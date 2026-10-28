std = "lua51"
max_line_length = false
-- Methods often ignore self (module tables); that is not a mistake.
self = false
exclude_files = { "Binds/Libs/" }

-- Globals Binds defines on purpose.
globals = {
	"Binds",
	"BindsDB",
	"SLASH_BINDS1",
	"SlashCmdList",
	"Binds_OnAddonCompartmentClick",
	"Binds_OnAddonCompartmentEnter",
	"Binds_OnAddonCompartmentLeave",
}

-- WoW API used by Binds; extend when new API is used.
read_globals = {
	"BugLab", "IsPlayerSpell", "IsMetaKeyDown", "UnitExists", "UnitIsFriend", "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "UIParent", "ClearOverrideBindings", "SetOverrideBindingClick", "GetMacroBody", "AddonList_InitButton", "AddonList_Update", "MAX_ADDONS_DISPLAYED", "GetAddOnInfo", "C_Timer", "issecretvalue", "bit", "C_ActionBar", "C_Item", "GetBindingKey", "GetMacroItem", "GetMacroSpell", "GetNumMacros", "GetNumShapeshiftForms", "GetShapeshiftFormInfo", "MAX_ACCOUNT_MACROS", "PixelUtil", "GetMacroInfo", "AddonCompartmentFrame", "GetBuildInfo",
	"UnitIsDeadOrGhost", "UnitLevel", "SettingsPanel", "HideUIPanel", "InterfaceOptionsFrame", "StaticPopupDialogs", "StaticPopup_Show", "ReloadUI", "C_Texture", "GetCursorInfo", "ClearCursor", "C_Container", "GetItemSpell", "GetContainerNumSlots", "GetContainerItemID", "GetSpellDescription", "UnitAffectingCombat", "GetItemCount", "GetItemInfo", "GetItemIcon", "UnitCanAttack", "UnitInParty", "UnitInRaid", "GetSpellBookItemInfo", "C_SpellBook", "GetNumSpellTabs", "GetSpellTabInfo", "IsPassiveSpell", "PartyFrame", "SecureHandlerWrapScript", "SecureButton_GetModifiedAttribute", "CompactUnitFrame_SetUnit",
	"C_AddOns", "C_ClickBindings", "GameMenuFrame", "CANCEL", "C_Spell", "ClickBindingFrame", "CreateFrame", "Enum",
	"GameTooltip", "GetActionInfo", "GetAddOnMetadata", "GetBindingText", "GetLocale", "GetSpellInfo",
	"hooksecurefunc", "InCombatLockdown", "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
	"IsAltKeyDown", "IsControlKeyDown", "IsShiftKeyDown", "ItemRefTooltip", "KeyBindingFrame",
	"KeyBindingFrame_LoadUI", "LibStub", "Settings", "ShowUIPanel", "strtrim", "ToggleClickBindingFrame",
	"TooltipDataProcessor", "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",
}
