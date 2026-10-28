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
StaticPopupDialogs["BINDS_RELOAD"] = {
	text = L.RELOAD_PROMPT,
	button1 = L.RELOAD_NOW,
	button2 = L.RELOAD_LATER,
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

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
	-- Text wraps only once it is laid out, so the height is measured a moment after every refresh.
	local function UpdateHeight()
		local top, bottom = content:GetTop(), content.last and content.last:GetBottom()
		if type(top) == "number" and type(bottom) == "number" then
			content:SetHeight(math.max(top - bottom + PADDING + 20, 1))
		end
	end
	local function Schedule()
		if C_Timer and C_Timer.After then
			C_Timer.After(0.05, UpdateHeight)
		end
	end
	table.insert(page.refreshers, Schedule)
	page:HookScript("OnShow", function()
		content:SetWidth(math.max(scroll:GetWidth(), 1))
		Schedule()
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
	local desc
	if description then
		desc = check:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
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

	if desc then
		-- Without the grey texts the explanation shows as a tooltip on the option; the label is clickable too.
		local width = text:GetStringWidth()
		if type(width) == "number" then
			check:SetHitRectInsets(0, -(width + 8), 0, 0)
		end
		check:SetScript("OnEnter", function(self)
			if Binds.db.showDescriptions == false then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(label, 1, 1, 1)
				GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
				GameTooltip:Show()
			end
		end)
		check:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		table.insert(panel.refreshers, function()
			local show = Binds.db.showDescriptions ~= false
			desc:SetShown(show)
			anchorFrame:SetPoint("BOTTOM", show and desc or check, "BOTTOM")
		end)
	end
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

	-- Display
	local displaySection = CreateSection(panel, header, L.SECTION_DISPLAY)
	local _, afterDisplay = CreateCheckbox(panel, displaySection, L.OPT_DESCRIPTIONS, L.OPT_DESCRIPTIONS_DESC,
		function() return Binds.db.showDescriptions ~= false end,
		function(value) Binds.db.showDescriptions = value end)

	-- Tooltip
	local tooltipSection = CreateSection(panel, afterDisplay, L.SECTION_TOOLTIP)

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
		function(value)
			Binds.db.mouseoverCasts = value
			-- Menu entries cannot be removed while the game runs, so the page only goes away after a reload.
			StaticPopup_Show("BINDS_RELOAD")
		end)

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

local ROW_HEIGHT = 53
local ICON_SIZE = 45

local IDLE_COLOR = { 0.45, 0.42, 0.40 }

-- Choice list for the second spell. Plain frames instead of a dropdown template: those differ between clients.
local PICK_ROWS, PICK_ROW_HEIGHT, PICK_WIDTH = 10, 24, 270
local picker
local ShowThingTooltip
local ShowArrowLegend

local function ChoosePick(entry)
	picker.catcher:Hide()
	if entry.action then
		entry.action()
	end
end

local function FillPicker()
	local entries = picker.entries
	local maxOffset = math.max(#entries - PICK_ROWS, 0)
	picker.offset = math.min(math.max(picker.offset, 0), maxOffset)
	for index, row in ipairs(picker.rows) do
		local entry = entries[picker.offset + index]
		row.entry = entry
		row.thing = entry and entry.thing
		if entry then
			row.icon:SetTexture(entry.texture)
			row.icon:SetDesaturated(entry.conflict and true or false)
			row.label:SetText(entry.conflict and ("|cff" .. Binds.colors.neutralDark.hex .. entry.name .. "|r") or entry.name)
			row:Show()
		else
			row:Hide()
		end
	end
	picker:SetHeight(math.min(#entries, PICK_ROWS) * PICK_ROW_HEIGHT + 16)
	-- Scroll bar on the right edge, only when the list is longer than the window.
	local scrolls = maxOffset > 0
	for _, row in ipairs(picker.rows) do
		row:SetPoint("RIGHT", picker, "RIGHT", scrolls and -22 or -8, 0)
	end
	picker.bar:SetShown(scrolls)
	if scrolls then
		picker.filling = true
		picker.bar:SetMinMaxValues(0, maxOffset)
		picker.bar:SetValue(picker.offset)
		picker.filling = false
	end
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

	picker = CreateFrame("Frame", nil, catcher, BackdropTemplateMixin and "BackdropTemplate" or nil)
	picker.catcher = catcher
	picker:SetFrameStrata("FULLSCREEN_DIALOG")
	picker:SetWidth(PICK_WIDTH)
	picker:EnableMouse(true)
	picker:EnableMouseWheel(true)
	picker.rows, picker.offset, picker.entries = {}, 0, {}

	-- Same frame as a tooltip.
	if picker.SetBackdrop then
		picker:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		picker:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
		picker:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	end

	local bar = CreateFrame("Slider", nil, picker)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(8)
	bar:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -8, -8)
	bar:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -8, 8)
	bar:SetValueStep(1)
	if bar.SetObeyStepOnDrag then
		bar:SetObeyStepOnDrag(true)
	end
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints()
	track:SetColorTexture(1, 1, 1, 0.08)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 28)
	thumb:SetColorTexture(Binds.colors.primary.r, Binds.colors.primary.g, Binds.colors.primary.b, 0.8)
	bar:SetThumbTexture(thumb)
	bar:SetScript("OnValueChanged", function(_, value)
		if not picker.filling then
			picker.offset = math.floor((value or 0) + 0.5)
			FillPicker()
		end
	end)
	bar:Hide()
	picker.bar = bar

	for index = 1, PICK_ROWS do
		local row = CreateFrame("Button", nil, picker)
		row:SetHeight(PICK_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", 8, -8 - (index - 1) * PICK_ROW_HEIGHT)
		row:SetPoint("RIGHT", -8, 0)
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
				ChoosePick(self.entry)
			end
		end)
		-- The game's own tooltip for the spell or item under the mouse.
		row:SetScript("OnEnter", function(self)
			if self.thing then
				ShowThingTooltip(self)
			end
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		picker.rows[index] = row
	end

	picker:SetScript("OnMouseWheel", function(self, delta)
		self.offset = self.offset - delta
		FillPicker()
	end)
	return picker
end

-- Shows `entries` below `slot`; each entry has a name, a texture and an action that runs when it is picked.
-- Retail has the game's own menu: its frame and scroll bar are the same as in Blizzard's settings dropdowns. Other
-- clients get the plain frames below.
local menuAnchor

local function ShowGameMenu(slot, entries)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then
		return false
	end
	local muted = Binds.colors.neutralDark.hex
	local function Generate(_, root)
		if root.SetScrollMode then
			root:SetScrollMode(PICK_ROWS * PICK_ROW_HEIGHT)
		end
		for _, entry in ipairs(entries) do
			local name = entry.conflict and ("|cff" .. muted .. entry.name .. "|r") or entry.name
			local text = entry.texture and ("|T%s:18|t %s"):format(tostring(entry.texture), name) or name
			local button = root:CreateButton(text, function()
				if entry.action then
					entry.action()
				end
			end)
			local thing = entry.thing
			if thing and button and button.SetTooltip then
				button:SetTooltip(function(tooltip)
					if thing.spell then
						tooltip:SetSpellByID(thing.spell)
					elseif thing.item and tooltip.SetItemByID then
						tooltip:SetItemByID(thing.item)
					end
				end)
			end
		end
	end

	-- An invisible dropdown button over the slot opens the menu directly below it, like the settings dropdowns do.
	if menuAnchor == nil then
		local created, frame = pcall(CreateFrame, "DropdownButton", nil, UIParent, "WowStyle1DropdownTemplate")
		menuAnchor = created and frame or false
		if menuAnchor then
			menuAnchor:SetAlpha(0)
			menuAnchor:EnableMouse(false)
		end
	end
	if menuAnchor and menuAnchor.SetupMenu and menuAnchor.OpenMenu then
		menuAnchor:ClearAllPoints()
		menuAnchor:SetAllPoints(slot)
		local ok = pcall(function()
			menuAnchor:SetupMenu(Generate)
			menuAnchor:OpenMenu()
		end)
		if ok then
			return true
		end
	end
	return (pcall(MenuUtil.CreateContextMenu, slot, Generate))
end

local function ShowPicker(slot, entries)
	if ShowGameMenu(slot, entries) then
		return
	end
	local frame = GetPicker()
	frame.offset = 0
	frame.entries = entries
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -2)
	FillPicker()
	frame.catcher:Show()
end

local function ClearEntry(action)
	return { name = "|cff" .. Binds.colors.neutralDark.hex .. L.SECOND_CLEAR .. "|r", action = action }
end

local function OpenPicker(slot)
	local clickSpells = Binds:GetModule("ClickSpells")
	local first = slot.row.spellID
	local entries = {}
	-- First entry empties the slot, but only while there is something to empty.
	if clickSpells:GetStoredSecond(first) then
		table.insert(entries, ClearEntry(function()
			clickSpells:SetSecond(first, nil)
			Binds:Fire("SettingsChanged")
			Refresh(clickPanel)
		end))
	end
	for _, candidate in ipairs(clickSpells:GetCandidates(first)) do
		-- Spells of the same kind do not work as a pair; they are only offered when asked for.
		if Binds.db.clicks.showAll or not candidate.conflict then
			table.insert(entries, {
				name = candidate.name, conflict = candidate.conflict, thing = { spell = candidate.spellID },
				texture = clickSpells:GetTexture(candidate.spellID),
				action = function()
					local ok, inactive = clickSpells:SetSecond(first, candidate.spellID)
					if not ok then
						Binds:Print(L.SECOND_ERR_UNKNOWN)
						return
					end
					if inactive then
						Binds:Print(L.SECOND_WARN_SAME)
					end
					Binds:Fire("SettingsChanged")
					Refresh(clickPanel)
				end,
			})
		end
	end
	if #entries == 0 then
		Binds:Print(L.SECOND_PICK_NONE)
		return
	end
	ShowPicker(slot, entries)
end

-- Combat resurrection: the class spells, then items from the bags that look like a resurrection (all items with a
-- use effect while "Show all spells" is on).
local function OpenCombatPicker(slot)
	local clickSpells = Binds:GetModule("ClickSpells")
	local entries = {}
	local function Choose(key)
		return function()
			clickSpells:SetCombatResurrection(key)
			Binds:Fire("SettingsChanged")
			Refresh(clickPanel)
		end
	end
	if Binds.db.clicks.combatRez then
		table.insert(entries, ClearEntry(Choose(nil)))
	end
	for _, choice in ipairs(clickSpells:GetCombatChoices()) do
		table.insert(entries, {
			name = clickSpells:ChoiceName(choice) or "?",
			texture = clickSpells:ChoiceTexture(choice),
			thing = { spell = choice.id },
			action = Choose(choice.key),
		})
	end
	for _, item in ipairs(clickSpells:GetBagItems(Binds.db.clicks.showAll)) do
		table.insert(entries, {
			name = item.name, texture = item.texture, thing = { item = item.id }, conflict = not item.usable,
			action = item.usable and Choose("item:" .. item.id) or function()
				Binds:Print(L.REZ_ITEM_UNUSABLE:format(item.name, item.reason or L.REZ_ITEM_UNUSABLE_REASON))
			end,
		})
	end
	if #entries == 0 then
		Binds:Print(L.REZ_PICK_NONE)
		return
	end
	ShowPicker(slot, entries)
end

-- Square icon button: an icon in a thin frame, the game's own tooltip for the spell or item on mouseover.
-- `button.thing` = { spell = id } or { item = id }; `button.hint` adds a line below the tooltip.
function ShowThingTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	local thing = button.thing
	if thing and thing.spell then
		GameTooltip:SetSpellByID(thing.spell)
	elseif thing and thing.item then
		if GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(thing.item)
		else
			GameTooltip:SetHyperlink("item:" .. thing.item)
		end
	else
		GameTooltip:SetText(button.emptyTitle or "", 1, 1, 1)
	end
	if button.hint then
		GameTooltip:AddLine(button.hint, 0.7, 0.7, 0.7, true)
	end
	if button.settingsHint then
		local action, key = Binds.colors.primary, Binds.colors.neutralLight
		GameTooltip:AddDoubleLine(L.HINT_CLICKCAST, L.CLICK_SHIFT_LEFT, action.r, action.g, action.b, key.r, key.g, key.b)
	end
	if button.warning then
		GameTooltip:AddLine(button.warning, 1, 0.82, 0, true)
	end
	if button.inactive then
		GameTooltip:AddLine(L.SECOND_WARN_SAME, 1, 0.82, 0, true)
	end
	GameTooltip:Show()
end

-- Retail draws its action buttons from atlases (frame, empty slot, mask); other clients get a plain thin frame.
local FRAME_ATLAS = "UI-HUD-ActionBar-IconFrame"

local function HasAtlas(name)
	if not (C_Texture and C_Texture.GetAtlasInfo) then
		return false
	end
	local ok, info = pcall(C_Texture.GetAtlasInfo, name)
	return ok and info ~= nil
end

-- Square icon button (45x45, like an action button) in the look of the action buttons.
local function CreateIconButton(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(ICON_SIZE, ICON_SIZE)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	button.icon = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	button.icon:SetAllPoints()
	-- Empty slot: a plus sign in the neutral color.
	button.plus = button:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
	button.plus:SetPoint("CENTER", 0, 1)
	button.plus:SetText("+")

	if HasAtlas(FRAME_ATLAS) then
		local background = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		background:SetAllPoints()
		background:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
		button.slotArt = button:CreateTexture(nil, "BACKGROUND", nil, 0)
		button.slotArt:SetAllPoints()
		button.slotArt:SetAtlas("ui-hud-actionbar-iconframe-slot")

		local mask = button:CreateMaskTexture()
		mask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask", false, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		-- As on the game's buttons the mask keeps its own proportions to the 45x45 button, not the icon's size;
		-- a mask stretched to the icon would shrink the visible icon.
		local scale = ICON_SIZE / 45
		local ok, info = pcall(C_Texture.GetAtlasInfo, "UI-HUD-ActionBar-IconFrame-Mask")
		if ok and info and info.width and info.height then
			mask:SetSize(info.width * scale, info.height * scale)
			mask:SetPoint("CENTER", button.icon)
		else
			mask:SetAllPoints(button.icon)
		end
		button.icon:AddMaskTexture(mask)

		-- The game's 46x45 frame on a 45x45 button, in proportion.
		local width, height = ICON_SIZE * 46 / 45, ICON_SIZE
		local frame = button:CreateTexture(nil, "OVERLAY")
		frame:SetAtlas(FRAME_ATLAS)
		frame:SetSize(width, height)
		frame:SetPoint("TOPLEFT")
		local highlight = button:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
		highlight:SetSize(width, height)
		highlight:SetPoint("TOPLEFT")
		button.pushed = button:CreateTexture(nil, "OVERLAY", nil, 1)
		button.pushed:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
		button.pushed:SetSize(width, height)
		button.pushed:SetPoint("TOPLEFT")
		button.pushed:Hide()
		button:SetScript("OnMouseDown", function(self)
			self.pushed:Show()
		end)
		button:SetScript("OnMouseUp", function(self)
			self.pushed:Hide()
		end)
	else
		local border = button:CreateTexture(nil, "BACKGROUND", nil, -2)
		border:SetAllPoints()
		border:SetColorTexture(Binds.colors.taupe.r, Binds.colors.taupe.g, Binds.colors.taupe.b, 0.9)
		local fill = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		fill:SetPoint("TOPLEFT", 1, -1)
		fill:SetPoint("BOTTOMRIGHT", -1, 1)
		fill:SetColorTexture(0.06, 0.05, 0.04, 0.9)
		button.icon:ClearAllPoints()
		button.icon:SetPoint("TOPLEFT", 2, -2)
		button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		local highlight = button:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetColorTexture(Binds.colors.accent.r, Binds.colors.accent.g, Binds.colors.accent.b, 0.25)
	end

	button:SetScript("OnEnter", ShowThingTooltip)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return button
end

-- Fills an icon button with a spell, an item or nothing.
local function SetThing(button, thing, texture)
	button.thing = thing
	button.icon:SetTexture(texture)
	button.icon:SetShown(texture ~= nil)
	button.plus:SetShown(texture == nil and button.isSlot == true)
	if button.slotArt then
		button.slotArt:SetShown(texture == nil)
	end
end

-- The slider arrow of the game (Retail atlas). A plain color fill is cut out with the arrow as a mask, so the color
-- keeps its full brightness; the grey original would only be darkened by a tint. The right arrow is the left one turned
-- by half a circle. Other clients get our own white arrow heads, tinted the same way.
local ARROW_HEIGHT = 18

local function CreateArrow(parent, pointsLeft)
	local arrow = parent:CreateTexture(nil, "ARTWORK")
	local atlas = "Minimal_SliderBar_Button_Left"
	local ok, info = pcall(function()
		return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
	end)
	if ok and info and info.width and info.height and info.height > 0 and parent.CreateMaskTexture then
		arrow:SetSize(ARROW_HEIGHT * info.width / info.height, ARROW_HEIGHT)
		arrow:SetColorTexture(1, 1, 1, 1)
		local mask = parent:CreateMaskTexture()
		mask:SetAtlas(atlas)
		mask:SetAllPoints(arrow)
		if not pointsLeft then
			mask:SetRotation(math.pi)
		end
		arrow:AddMaskTexture(mask)
	else
		arrow:SetSize(13, 18)
		arrow:SetTexture(Binds.mediaPath .. (pointsLeft and "arrow_links_weiss_32x32" or "arrow_weiss_32x32"))
	end
	return arrow
end

local function SetArrowColor(arrow, kind)
	local color = Binds:GetModule("ClickSpells").KIND_COLORS[kind]
	if color then
		arrow:SetVertexColor(color.r, color.g, color.b)
	else
		arrow:SetVertexColor(IDLE_COLOR[1], IDLE_COLOR[2], IDLE_COLOR[3])
	end
end

local LEGEND = {
	{ "friend", "LEGEND_FRIEND" },
	{ "enemy", "LEGEND_ENEMY" },
	{ "buff", "LEGEND_BUFF" },
	{ "dispel", "LEGEND_DISPEL" },
}

function ShowArrowLegend(anchor)
	local clickSpells = Binds:GetModule("ClickSpells")
	GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
	Binds:AddTooltipHeader(GameTooltip)
	local primary, muted = Binds.colors.primary, Binds.colors.neutralDark
	GameTooltip:AddLine(L.LEGEND_TITLE, primary.r, primary.g, primary.b)
	GameTooltip:AddLine(L.LEGEND_INTRO, muted.r, muted.g, muted.b, true)
	GameTooltip:AddLine(" ")
	local entries = {}
	for _, entry in ipairs(LEGEND) do
		table.insert(entries, { color = clickSpells.KIND_COLORS[entry[1]], name = L[entry[2]], desc = L[entry[2] .. "_DESC"] })
	end
	table.insert(entries, { color = { r = IDLE_COLOR[1], g = IDLE_COLOR[2], b = IDLE_COLOR[3] }, name = L.LEGEND_EMPTY, desc = L.LEGEND_EMPTY_DESC })
	for _, entry in ipairs(entries) do
		local color = entry.color
		GameTooltip:AddLine(clickSpells:ArrowString(true, color) .. " " .. entry.name, color.r, color.g, color.b)
		GameTooltip:AddLine("    " .. entry.desc, muted.r, muted.g, muted.b, true)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L.LEGEND_POINTS, 0.9, 0.9, 0.9, true)
	GameTooltip:AddLine(L.LEGEND_CONFLICT, muted.r, muted.g, muted.b, true)
	GameTooltip:Show()
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

	-- The click cast itself; not changeable here, it comes from Blizzard's click casting settings.
	row.first = CreateIconButton(row)
	row.first:SetPoint("LEFT", 164, 0)
	row.first.settingsHint = true
	row.first:SetScript("OnClick", function()
		if not IsShiftKeyDown() then
			return
		end
		if InCombatLockdown() then
			Binds:Print(L.COMBAT_LOCKED)
		else
			Binds:OpenClickCastSettingsFromOptions()
		end
	end)

	-- Two arrows side by side: the left one points back at the click cast, the right one at the second spell.
	-- They sit in the middle between the click cast and the second spell slot.
	local middle = CreateFrame("Frame", nil, row)
	middle:SetSize(1, 1)
	middle:SetPoint("LEFT", row.first, "RIGHT", 35, 0)
	row.arrowFirst = CreateArrow(row, true)
	row.arrowFirst:SetPoint("RIGHT", middle, "CENTER", -2, 0)
	row.arrowSecond = CreateArrow(row, false)
	row.arrowSecond:SetPoint("LEFT", middle, "CENTER", 2, 0)
	-- Legend of the arrow colors while the mouse is over the arrows.
	local legend = CreateFrame("Frame", nil, row)
	legend:SetSize(34, 22)
	legend:SetPoint("CENTER", middle, "CENTER", 0, 0)
	legend:EnableMouse(true)
	legend:SetScript("OnEnter", ShowArrowLegend)
	legend:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row.slot = CreateIconButton(row)
	row.slot.isSlot = true
	row.slot.row = row
	row.slot:SetPoint("LEFT", row.first, "RIGHT", 70, 0)
	row.slot.emptyTitle = L.SECOND_EMPTY
	row.slot:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			Binds:GetModule("ClickSpells"):SetSecond(self.row.spellID, nil)
			Binds:Fire("SettingsChanged")
			Refresh(clickPanel)
		else
			OpenPicker(self)
		end
	end)

	-- Warning badge for a pair of the same kind: drawn here, tooltip carries the reason.
	row.warn = CreateFrame("Frame", nil, row)
	row.warn:SetSize(22, 22)
	row.warn:SetPoint("LEFT", row.slot, "RIGHT", 8, 0)
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

	row.none = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	row.none:SetPoint("LEFT", row.first, "RIGHT", 8, 0)
	row.none:SetText(L.SECOND_NONE)
	return row
end

do
	local panel = CreateScrollContent(clickPanel)
	local header = CreateHeader(panel, L.CATEGORY_CLICK, L.CLICK_SUBTITLE)
	local subtitle = L.CLICK_SUBTITLE
	clickPanel:SetScript("OnHide", function()
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
			SetThing(row.first, { spell = click.spellID }, clickSpells:GetTexture(click.spellID))
			SetArrowColor(row.arrowFirst, clickSpells:Kind(click.spellID))

			-- Spells that act on neither friends nor enemies have no counterpart.
			local pairable = clickSpells:Orientation(click.spellID) ~= nil
			row.slot:SetShown(pairable)
			row.arrowFirst:SetShown(pairable)
			row.arrowSecond:SetShown(pairable)
			row.none:SetShown(not pairable)
			local second = clickSpells:GetStoredSecond(click.spellID)
			local inactive = second and clickSpells:Conflicts(click.spellID, second)
			row.slot.inactive = inactive
			row.slot.hint = L.SECOND_SLOT_HINT
			SetThing(row.slot, second and { spell = second } or nil, second and clickSpells:GetTexture(second) or nil)
			row.slot.icon:SetDesaturated(inactive and true or false)
			SetArrowColor(row.arrowSecond, (second and not inactive) and clickSpells:Kind(second) or nil)
			row.warn:SetShown(inactive and true or false)
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

	-- Out of combat the normal resurrection, in combat the chosen one (spell or engineering item).
	local normalLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	normalLabel:SetPoint("TOPLEFT", afterRes, "BOTTOMLEFT", 30, -24)
	normalLabel:SetWidth(200)
	normalLabel:SetJustifyH("LEFT")
	local normalIcon = CreateIconButton(panel)
	normalIcon:SetPoint("LEFT", normalLabel, "RIGHT", 4, 0)

	local combatLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	combatLabel:SetPoint("TOPLEFT", normalLabel, "BOTTOMLEFT", 0, -(ICON_SIZE - 8))
	combatLabel:SetWidth(200)
	combatLabel:SetJustifyH("LEFT")
	combatLabel:SetText(L.RESURRECT_COMBAT)
	local combatSlot = CreateIconButton(panel)
	combatSlot.isSlot = true
	combatSlot:SetPoint("LEFT", combatLabel, "RIGHT", 4, 0)
	combatSlot.hint = L.REZ_SLOT_HINT
	combatSlot.emptyTitle = L.RESURRECT_COMBAT
	combatSlot:SetScript("OnClick", function(self, button)
		if self.unavailable then
			return
		end
		if button == "RightButton" then
			Binds:GetModule("ClickSpells"):SetCombatResurrection(nil)
			Binds:Fire("SettingsChanged")
			Refresh(clickPanel)
		else
			OpenCombatPicker(self)
		end
	end)

	local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	note:SetJustifyH("LEFT")
	note:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)

	-- Last anchor of the page, for the scroll height.
	local pageEnd = CreateFrame("Frame", nil, panel)
	pageEnd:SetSize(1, 1)
	panel.last = pageEnd

	table.insert(panel.refreshers, function()
		local clickSpells = Binds:GetModule("ClickSpells")
		local normal = clickSpells:GetNormalResurrection()
		local combat = clickSpells:GetCombatResurrection()
		local any = normal or combat
		resCheck:SetShown(any ~= nil)
		for _, widget in ipairs({ normalLabel, normalIcon, combatLabel, combatSlot }) do
			widget:SetShown(any ~= nil)
		end
		note:ClearAllPoints()
		-- The right anchor gives the text its width, so it wraps.
		note:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
		pageEnd:ClearAllPoints()
		if not any then
			note:SetPoint("TOPLEFT", resSection, "BOTTOMLEFT", 0, -8)
			note:SetText(L.RESURRECT_UNAVAILABLE)
		else
			note:SetPoint("TOPLEFT", combatLabel, "BOTTOMLEFT", 0, -(ICON_SIZE - 14))
			local unavailable = #clickSpells:GetCombatChoices() == 0 and #clickSpells:GetBagItems(false) == 0
			note:SetText(unavailable and L.RESURRECT_NOTE_NONE or L.RESURRECT_NOTE)
			normalLabel:SetText(L.RESURRECT_NORMAL .. (normal and "" or " |cff" .. Binds.colors.neutralDark.hex .. "(" .. L.RESURRECT_NONE .. ")|r"))
			SetThing(normalIcon, normal and { spell = normal } or nil, normal and clickSpells:GetTexture(normal) or nil)
			SetThing(combatSlot, combat and { [combat.kind] = combat.id } or nil, clickSpells:ChoiceTexture(combat))
			-- No combat resurrection for this class and nothing in the bags: the field is greyed out with a note.
			combatSlot.unavailable = unavailable
			-- A configured item that is not in the bags (or cannot be used) stays visible, greyed out.
			local stored = Binds.db.clicks.combatRez
			local storedItem = stored and tonumber(stored:match("^item:(%d+)$"))
			local missing = storedItem and not (combat and combat.kind == "item" and combat.id == storedItem)
			if missing then
				SetThing(combatSlot, { item = storedItem }, clickSpells:ItemTexture(storedItem))
			end
			combatSlot.icon:SetDesaturated(missing and true or false)
			combatSlot.icon:SetAlpha(missing and 0.6 or 1)
			combatSlot.warning = missing and L.REZ_ITEM_MISSING or nil
			combatSlot.hint = unavailable and nil or L.REZ_SLOT_HINT
			combatSlot:SetAlpha(unavailable and 0.45 or 1)
			-- Fully inert while unavailable: no click, no hover effect, no tooltip.
			combatSlot:EnableMouse(not unavailable)
			combatLabel:SetFontObject(unavailable and "GameFontDisable" or "GameFontHighlight")
			combatLabel:SetText(L.RESURRECT_COMBAT .. (unavailable and (" |cff" .. Binds.colors.neutralDark.hex .. "(" .. L.REZ_COMBAT_UNAVAILABLE .. ")|r") or ""))
		end
		pageEnd:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -PADDING)
	end)

	-- Cover for the page while the main switch is off: nothing on it can be clicked, and it says why.
	local cover = CreateFrame("Frame", nil, clickPanel)
	cover:SetAllPoints(clickPanel)
	cover:SetFrameLevel(clickPanel:GetFrameLevel() + 100)
	cover:EnableMouse(true)
	cover:EnableMouseWheel(true)
	cover:SetScript("OnMouseWheel", function() end)
	local coverShade = cover:CreateTexture(nil, "BACKGROUND")
	coverShade:SetAllPoints()
	coverShade:SetColorTexture(0.03, 0.025, 0.02, 0.8)
	local coverText = cover:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	coverText:SetPoint("CENTER", 0, 40)
	coverText:SetWidth(460)
	coverText:SetText(Binds:Colorize(L.CLICK_COVER_TITLE, "primary") .. "\n\n|cff" .. Binds.colors.neutralLight.hex .. L.CLICK_COVER_TEXT .. "|r")
	table.insert(panel.refreshers, function()
		cover:SetShown(not Binds.db.mouseoverCasts)
	end)
	cover:Hide()

	-- Everything on this page rides on the mouseover module; say so when it is off.
	table.insert(panel.refreshers, function()
		local off = not Binds.db.mouseoverCasts
		header:SetText(off and (subtitle .. "\n|cff" .. Binds.colors.primary.hex .. L.CLICK_DISABLED .. "|r") or subtitle)
	end)
end

----------------------------------------------------------------------
-- Subcategory: Backup
----------------------------------------------------------------------

StaticPopupDialogs["BINDS_IMPORT"] = {
	text = "%s",
	button1 = L.BACKUP_IMPORT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		if data and data.run then
			data.run()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- Green check mark in front of a successful import.
local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16:0:-1|t "

local backupPanel = CreatePanel(L.CATEGORY_BACKUP)
backupPanel.parent = mainPanel.name

do
	local state = { scope = "account", blizzard = true }
	local panel = CreateScrollContent(backupPanel)
	local header = CreateHeader(panel, L.CATEGORY_BACKUP, L.BACKUP_SUBTITLE)

	-- Multi-line text field that grows with its text, so the whole backup text is always visible. Returns the frame
	-- (for anchoring) and the edit box.
	local function CreateTextBox(anchor)
		local font = ChatFontNormal or GameFontHighlight
		local frame = CreateFrame("Frame", nil, panel, BackdropTemplateMixin and "BackdropTemplate" or nil)
		frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
		frame:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
		frame:SetHeight(60)
		if frame.SetBackdrop then
			frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 12,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			})
			frame:SetBackdropColor(0, 0, 0, 0.5)
			frame:SetBackdropBorderColor(0.45, 0.4, 0.36, 1)
		end

		local box = CreateFrame("EditBox", nil, frame)
		box:SetMultiLine(true)
		box:SetFontObject(font)
		box:SetAutoFocus(false)
		box:SetMaxLetters(0)
		box:SetPoint("TOPLEFT", 8, -8)
		box:SetPoint("TOPRIGHT", -8, -8)
		box:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
		end)

		local measure = frame:CreateFontString(nil, "ARTWORK")
		measure:SetFontObject(font)
		measure:SetJustifyH("LEFT")
		measure:Hide()

		local function Fit()
			local width = frame:GetWidth()
			if type(width) ~= "number" or width < 60 then
				width = math.max((panel:GetWidth() or 0) - 2 * PADDING, 200)
			end
			width = width - 16
			measure:SetWidth(width)
			-- Break characters of a long text without spaces: the text is measured with a space after each 40 characters.
			measure:SetText(((box:GetText() or ""):gsub("(" .. ("."):rep(40) .. ")", "%1 ")))
			local height = measure:GetStringHeight()
			height = type(height) == "number" and height or 40
			box:SetHeight(math.max(height, 40) + 18)
			frame:SetHeight(math.max(height, 40) + 34)
		end
		box:SetScript("OnTextChanged", function()
			Fit()
			Refresh(backupPanel)
		end)
		table.insert(panel.refreshers, Fit)
		return frame, box
	end

	local function CreateButton(label, anchor, x)
		local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		button:SetSize(150, 24)
		button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, -10)
		button:SetText(label)
		return button
	end

	local function Status(anchor)
		local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
		text:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
		text:SetJustifyH("LEFT")
		return text
	end

	-- What to back up
	local section = CreateSection(panel, header, L.BACKUP_SECTION_SCOPE)
	local _, afterScope = CreateCheckbox(panel, section, L.BACKUP_SCOPE_ACCOUNT, L.BACKUP_SCOPE_ACCOUNT_DESC,
		function() return state.scope == "account" end,
		function(on) if on then state.scope = "account" end end)
	local _, afterChar = CreateCheckbox(panel, afterScope, L.BACKUP_SCOPE_CHARACTER, L.BACKUP_SCOPE_CHARACTER_DESC,
		function() return state.scope == "character" end,
		function(on) if on then state.scope = "character" end end)
	local blizzardCheck, afterBlizzard = CreateCheckbox(panel, afterChar, L.BACKUP_BLIZZARD, L.BACKUP_BLIZZARD_DESC,
		function() return state.blizzard end,
		function(on) state.blizzard = on end, 24)
	table.insert(panel.refreshers, function()
		SetCheckboxEnabled(blizzardCheck, true)
	end)

	-- Export
	local exportSection = CreateSection(panel, afterBlizzard, L.BACKUP_SECTION_EXPORT)
	local exportButton = CreateButton(L.BACKUP_EXPORT, exportSection)
	local exportFrame, exportBox = CreateTextBox(exportButton)
	local exportStatus = Status(exportFrame)
	exportButton:SetScript("OnClick", function()
		local text = Binds:GetModule("Backup"):Export(state.scope, state.blizzard)
		exportBox.shown = text
		exportBox:SetText(text)
		exportBox:SetFocus()
		exportBox:HighlightText()
		exportStatus:SetText(L.BACKUP_EXPORT_DONE)
	end)
	-- The text is a copy; keep the box from being edited into something else.
	exportBox:SetScript("OnChar", function(self)
		self:SetText(self.shown or "")
		self:HighlightText()
	end)

	-- Import
	local importSection = CreateSection(panel, exportStatus, L.BACKUP_SECTION_IMPORT)
	local importHint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	importHint:SetPoint("TOPLEFT", importSection, "BOTTOMLEFT", 0, -8)
	importHint:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
	importHint:SetJustifyH("LEFT")
	importHint:SetText(L.BACKUP_IMPORT_HINT)
	local importFrame, importBox = CreateTextBox(importHint)
	local importButton = CreateButton(L.BACKUP_IMPORT, importFrame)
	local importStatus = Status(importButton)

	importButton:SetScript("OnClick", function()
		local text = importBox:GetText() or ""
		local backup = Binds:GetModule("Backup")
		local scope = text:match("^%s*BINDS1:(%a+):")
		local from = text:match("^%s*BINDS1:character:([^:%s]+):[^:%s]+:[^:%s]+%s*$")
		if not scope then
			importStatus:SetText("|cffff6060" .. L.BACKUP_ERROR_FORMAT .. "|r")
			return
		end
		local function run()
			local before = Binds.db.mouseoverCasts
			local ok, result, count, blizzard, reason = backup:Import(text, state.blizzard)
			if not ok then
				importStatus:SetText("|cffff6060" .. (L["BACKUP_ERROR_" .. result] or L.BACKUP_ERROR_FORMAT) .. "|r")
				return
			end
			local message = result == "account" and L.BACKUP_DONE_ACCOUNT or L.BACKUP_DONE_CHARACTER:format(count)
			message = CHECK .. message
			if blizzard then
				message = message .. " " .. L.BACKUP_DONE_BLIZZARD:format(blizzard)
			elseif reason then
				message = message .. " |cffff6060" .. (L["BACKUP_BLIZZARD_" .. reason] or "") .. "|r"
			end
			importStatus:SetText(message)
			importBox:SetText("")
			Binds:Fire("SettingsChanged")
			Refresh(backupPanel)
			if before ~= Binds.db.mouseoverCasts then
				StaticPopup_Show("BINDS_RELOAD")
			end
		end
		local confirm = scope == "account" and L.BACKUP_CONFIRM_ACCOUNT or L.BACKUP_CONFIRM_CHARACTER
		if from then
			confirm = confirm .. "\n\n" .. L.BACKUP_FROM:format(from)
		end
		StaticPopup_Show("BINDS_IMPORT", confirm, nil, { run = run })
	end)

	panel.last = importStatus
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
			Settings.RegisterCanvasLayoutSubcategory(category, backupPanel, backupPanel.name)
		end
		Settings.RegisterAddOnCategory(category)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(mainPanel)
		InterfaceOptions_AddCategory(generalPanel)
		if Binds.db.mouseoverCasts then
			InterfaceOptions_AddCategory(clickPanel)
		end
		InterfaceOptions_AddCategory(backupPanel)
	end
end
