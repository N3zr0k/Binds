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
	local panel = generalPanel
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

	-- Minimap
	local minimapSection = CreateSection(panel, modifierChecks[1], L.SECTION_MINIMAP)
	minimapSection:ClearAllPoints()
	minimapSection:SetPoint("TOPLEFT", modifierChecks[1], "BOTTOMLEFT", -30, -SECTION_GAP)

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

	CreateCheckbox(panel, developerSection, L.OPT_DEBUG, L.OPT_DEBUG_DESC,
		function() return Binds.db.debug end,
		function(value) Binds.db.debug = value end)
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

function Options:OnInitialize()
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
		Binds.settingsCategory = category
		if Settings.RegisterCanvasLayoutSubcategory then
			Binds.settingsSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, generalPanel, generalPanel.name)
		end
		Settings.RegisterAddOnCategory(category)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(mainPanel)
		InterfaceOptions_AddCategory(generalPanel)
	end
end
