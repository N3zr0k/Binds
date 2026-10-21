local _, ns = ...
ns.Locales = ns.Locales or {}

-- enUS is the fallback for every missing key in other locales.
ns.Locales.enUS = {
	CATEGORY_KEYBOARD = "Keyboard",
	CATEGORY_MOUSE = "Mouse",
	CATEGORY_CLICK = "Click Casting",

	CATEGORY_GENERAL = "General",

	OVERVIEW_TEXT = "Binds shows in tooltips how you trigger a spell, item or macro. It only reads bindings and never changes them.",
	VERSION = "Version",
	AUTHOR = "Author",

	OPT_SHOW_TOOLTIP = "Show bindings in tooltips",
	OPT_MODIFIER_FILTER = "Only show while a modifier key is held",
	OPT_MODIFIER_SHIFT = "Shift",
	OPT_MODIFIER_CTRL = "Ctrl",
	OPT_MODIFIER_ALT = "Alt",
	OPT_MINIMAP = "Show minimap button",
	OPT_DEBUG = "Debug output",

	-- Options layout
	GENERAL_SUBTITLE = "Settings apply to all characters on this account.",
	SECTION_TOOLTIP = "Tooltip",
	SECTION_CLICKCAST = "Click casting",
	OPT_MOUSEOVER = "Mouseover casts in the world",
	OPT_MOUSEOVER_DESC = "Click casts with a modifier (e.g. Shift + right click) also work on units in the game world, as mouseover casts. The setup stays the one from Blizzard. Plain clicks are not affected; changes apply out of combat.",
	SECTION_MINIMAP = "Minimap & Titan Panel",
	SECTION_DEVELOPER = "Developer",
	OPT_SHOW_TOOLTIP_DESC = "Adds a Binds section to spell, item and macro tooltips.",
	OPT_CATEGORY_KEYBOARD_DESC = "Key bindings from the keyboard, e.g. 1 or Shift + F.",
	OPT_CATEGORY_MOUSE_DESC = "Mouse buttons and the mouse wheel bound to the action.",
	OPT_CATEGORY_CLICK_DESC = "Blizzard click casting on unit frames.",
	OPT_MODIFIER_FILTER_DESC = "The section appears as soon as one of the selected keys is held.",
	OPT_MINIMAP_DESC = "Titan Panel and the addon compartment are not affected.",
	OPT_DEBUG_DESC = "Writes debug lines to BugLab, or to chat if BugLab is not installed.",
	OVERVIEW_HINT = "All settings are in the General category.",

	HINT_OPTIONS = "Binds options",
	HINT_CLICKCAST = "Click Casting settings",
	HINT_KEYBINDS = "Key Bindings",
	CLICK_RIGHT = "Right-click",
	CLICK_SHIFT_LEFT = "Shift + left-click",
	CLICK_SHIFT_RIGHT = "Shift + right-click",
	CLICK_ACTION_TARGET = "Target unit",
	CLICK_ACTION_MENU = "Open menu",
	CLICK_ACTION_UNKNOWN = "Unknown action",
	BROKER_CLICKCAST_LIST = "List of configured click casts",
	BROKER_NO_CLICKCASTS = "No click casts configured.",
	BROKER_CLICKCAST_UNAVAILABLE = "Click casting is not available in this game client.",

	CMD_HELP = "Commands: /binds (options), /binds minimap (toggle minimap button)",
	CMD_UNKNOWN = "Unknown command.",
	COMBAT_LOCKED = "Not available in combat.",

	-- BugLab probes
	PROBE_ENV = "Environment",
	PROBE_ENV_DESC = "Shows which client features Binds detected.",
	PROBE_SCAN = "Rescan bindings",
	PROBE_SCAN_DESC = "Rebuilds the binding cache and counts the results.",
	PROBE_LOOKUP = "Bindings of an action",
	PROBE_LOOKUP_DESC = "Shows what the tooltip would show for a spell, item or macro.",
	PROBE_KEY = "Classify key",
	PROBE_KEY_DESC = "Category and display text of a binding key such as CTRL-BUTTON4.",
	PROBE_CLICKCASTS = "Click casts",
	PROBE_CLICKCASTS_DESC = "Lists Blizzard click casts as Binds reads them.",
	PROBE_PARAM_KIND = "Kind",
	PROBE_PARAM_ID = "ID",
	PROBE_PARAM_KEY = "Key",
}
