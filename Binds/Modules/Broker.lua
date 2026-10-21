local _, ns = ...
local Binds = ns.Binds
local L = ns.L

-- Titan Panel, minimap button and addon compartment share one LibDataBroker object.
local Broker = Binds:RegisterModule("Broker")

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

local ICON = "Interface\\AddOns\\Binds\\Media\\Binds_Icon_64x64"
-- LibDBIcon draws icons at 18px; the Binds logo reads better a bit smaller inside the round border.
local MINIMAP_ICON_SIZE = 13

----------------------------------------------------------------------
-- Shortcuts
----------------------------------------------------------------------

-- Blizzard moved these panels between versions; try the known entry points and stop at the first that exists.
local function OpenClickCastSettings()
	if ToggleClickBindingFrame then
		ToggleClickBindingFrame()
	elseif ClickBindingFrame then
		ShowUIPanel(ClickBindingFrame)
	else
		Binds:Print(L.BROKER_CLICKCAST_UNAVAILABLE)
	end
end

local function OpenKeyBindings()
	if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
		Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID)
		return
	end
	if KeyBindingFrame_LoadUI then
		KeyBindingFrame_LoadUI()
	end
	if KeyBindingFrame then
		ShowUIPanel(KeyBindingFrame)
	end
end

local function HandleClick(button)
	if InCombatLockdown() then
		Binds:Print(L.COMBAT_LOCKED)
		return
	end
	if IsShiftKeyDown() then
		if button == "RightButton" then
			OpenKeyBindings()
		else
			OpenClickCastSettings()
		end
	elseif button == "RightButton" then
		Binds:OpenOptions()
	end
end

----------------------------------------------------------------------
-- Tooltip: all configured click casts
----------------------------------------------------------------------

-- Logo sits outside the tooltip on its left edge. One shared frame, re-parented to whichever tooltip shows it.
local LOGO = "Interface\\AddOns\\Binds\\Media\\Binds_Icon_und_Schrift_128x128"
local LOGO_SIZE = 72
local logoFrame

local function AttachLogo(tooltip)
	if not logoFrame then
		logoFrame = CreateFrame("Frame")
		logoFrame:SetSize(LOGO_SIZE, LOGO_SIZE)
		local texture = logoFrame:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetTexture(LOGO)
	end
	-- Shared tooltips (GameTooltip) are reused by other addons; detach on hide so the logo never leaks into them.
	if not tooltip.bindsLogoHooked then
		tooltip:HookScript("OnHide", function()
			if logoFrame:GetParent() == tooltip then
				logoFrame:Hide()
				logoFrame:SetParent(nil)
			end
		end)
		tooltip.bindsLogoHooked = true
	end
	logoFrame:SetParent(tooltip)
	logoFrame:SetFrameStrata(tooltip:GetFrameStrata())
	logoFrame:ClearAllPoints()
	logoFrame:SetPoint("TOPRIGHT", tooltip, "TOPLEFT", -6, 0)
	logoFrame:Show()
end

-- { action, click } locale keys, in the order shown.
local HINTS = {
	{ "HINT_OPTIONS", "CLICK_RIGHT" },
	{ "HINT_CLICKCAST", "CLICK_SHIFT_LEFT" },
	{ "HINT_KEYBINDS", "CLICK_SHIFT_RIGHT" },
}

local function FillTooltip(tooltip)
	AttachLogo(tooltip)
	tooltip:AddLine(Binds:Colorize(Binds.title, "primary"))
	local muted = Binds.colors.neutralDark
	tooltip:AddLine(Binds.version, muted.r, muted.g, muted.b)

	tooltip:AddLine(" ")
	local action, key = Binds.colors.primary, Binds.colors.neutralLight
	for _, hint in ipairs(HINTS) do
		tooltip:AddDoubleLine(L[hint[1]], L[hint[2]], action.r, action.g, action.b, key.r, key.g, key.b)
	end

	-- Click casts at the bottom, with the same header as the bindings section in other tooltips.
	tooltip:AddLine(" ")
	Binds:AddTooltipHeader(tooltip)
	local subtitle = Binds.colors.neutralLight
	tooltip:AddLine(L.BROKER_CLICKCAST_LIST, subtitle.r, subtitle.g, subtitle.b)
	local scanner = Binds:GetModule("Scanner")
	if not (scanner and scanner:IsClickCastingAvailable()) then
		tooltip:AddLine(L.BROKER_CLICKCAST_UNAVAILABLE, 1, 1, 1, true)
	else
		local casts = scanner:GetClickCasts()
		if #casts == 0 then
			tooltip:AddLine(L.BROKER_NO_CLICKCASTS, 1, 1, 1)
		end
		-- Same layout as the bindings section: what it does on the left, how to trigger it on the right.
		local color = Binds.categoryColors.click
		local light = Binds.categoryLightColors.click
		local icon = Binds:Texture("mouse-pointer-click_weiss_32x32", 0, color) .. " "
		for _, cast in ipairs(casts) do
			tooltip:AddDoubleLine(icon .. cast.name, cast.binding, color.r, color.g, color.b, light.r, light.g, light.b)
		end
	end
end

----------------------------------------------------------------------
-- Minimap
----------------------------------------------------------------------

function Broker:SetMinimapButtonShown(shown)
	Binds.db.minimap.hide = not shown
	if not LDBIcon then
		return
	end
	if shown then
		LDBIcon:Show(Binds.name)
	else
		LDBIcon:Hide(Binds.name)
	end
end

function Broker:ToggleMinimapButton()
	self:SetMinimapButtonShown(Binds.db.minimap.hide)
end

function Broker:OnEnable()
	if not LDB then
		return
	end
	self.dataObject = LDB:NewDataObject(Binds.name, {
		type = "launcher",
		label = Binds.title,
		icon = ICON,
		OnClick = function(_, button)
			HandleClick(button)
		end,
		OnTooltipShow = FillTooltip,
	})
	if LDBIcon then
		LDBIcon:Register(Binds.name, self.dataObject, Binds.db.minimap)
		if LDBIcon.SetButtonIcon then
			LDBIcon:SetButtonIcon(Binds.name, nil, MINIMAP_ICON_SIZE, "CENTER")
		end
	end
end

----------------------------------------------------------------------
-- Addon compartment (Retail; the TOC entries are ignored where it does not exist)
----------------------------------------------------------------------

function Binds_OnAddonCompartmentClick(_, button)
	HandleClick(button)
end

function Binds_OnAddonCompartmentEnter(_, frame)
	GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
	FillTooltip(GameTooltip)
	GameTooltip:Show()
end

function Binds_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end
