local _, ns = ...
ns.Locales = ns.Locales or {}

ns.Locales.deDE = {
	CATEGORY_KEYBOARD = "Tastatur",
	CATEGORY_MOUSE = "Maus",
	CATEGORY_CLICK = "Klickzauber",

	CATEGORY_GENERAL = "Allgemein",

	OVERVIEW_TEXT = "Binds zeigt im Tooltip, wie du einen Zauber, Gegenstand oder ein Makro auslöst. Belegungen werden nur gelesen, nie verändert.",
	VERSION = "Version",
	AUTHOR = "Autor",

	OPT_SHOW_TOOLTIP = "Belegungen im Tooltip anzeigen",
	OPT_MODIFIER_FILTER = "Nur anzeigen, solange eine Modifikatortaste gedrückt ist",
	OPT_MODIFIER_SHIFT = "Umschalt",
	OPT_MODIFIER_CTRL = "Strg",
	OPT_MODIFIER_ALT = "Alt",
	OPT_MINIMAP = "Minimap-Symbol anzeigen",
	OPT_DEBUG = "Debug-Ausgabe",

	-- Options layout
	GENERAL_SUBTITLE = "Die Einstellungen gelten für alle Charaktere dieses Kontos.",
	SECTION_TOOLTIP = "Tooltip",
	SECTION_CLICKCAST = "Klickzauber",
	OPT_MOUSEOVER = "Mouseover-Zauber in der Spielwelt",
	OPT_MOUSEOVER_DESC = "Klickzauber mit Modifikator (z. B. Umschalt + Rechtsklick) wirken auch auf Einheiten in der Spielwelt, als Mouseover-Zauber. Die Einstellungen bleiben die von Blizzard. Einfache Klicks bleiben unberührt; Änderungen gelten außerhalb des Kampfes.",
	SECTION_MINIMAP = "Minimap & Titan Panel",
	SECTION_DEVELOPER = "Entwickler",
	OPT_SHOW_TOOLTIP_DESC = "Fügt Zauber-, Gegenstands- und Makro-Tooltips einen Binds-Abschnitt hinzu.",
	OPT_CATEGORY_KEYBOARD_DESC = "Belegungen auf der Tastatur, z. B. 1 oder Umschalt + F.",
	OPT_CATEGORY_MOUSE_DESC = "Maustasten und Mausrad, die auf der Aktion liegen.",
	OPT_CATEGORY_CLICK_DESC = "Blizzard-Klickzauber auf Einheitenfenstern.",
	OPT_MODIFIER_FILTER_DESC = "Der Abschnitt erscheint, sobald eine der gewählten Tasten gedrückt ist.",
	OPT_MINIMAP_DESC = "Titan Panel und Addon-Compartment sind davon nicht betroffen.",
	OPT_DEBUG_DESC = "Schreibt Debug-Zeilen in BugLab oder, ohne BugLab, in den Chat.",
	OVERVIEW_HINT = "Alle Einstellungen findest du in der Kategorie Allgemein.",

	HINT_OPTIONS = "Binds-Optionen",
	HINT_CLICKCAST = "Klickzauber-Einstellungen",
	HINT_KEYBINDS = "Tastaturbelegung",
	CLICK_RIGHT = "Rechtsklick",
	CLICK_SHIFT_LEFT = "Umschalt + Linksklick",
	CLICK_SHIFT_RIGHT = "Umschalt + Rechtsklick",
	CLICK_ACTION_TARGET = "Ziel auswählen",
	CLICK_ACTION_MENU = "Menü öffnen",
	CLICK_ACTION_UNKNOWN = "Unbekannte Aktion",
	BROKER_CLICKCAST_LIST = "Liste der konfigurierten Klickzauber",
	BROKER_NO_CLICKCASTS = "Keine Klickzauber eingerichtet.",
	BROKER_CLICKCAST_UNAVAILABLE = "Klickzauber gibt es in diesem Spielclient nicht.",

	CMD_HELP = "Befehle: /binds (Optionen), /binds minimap (Minimap-Symbol ein/aus)",
	CMD_UNKNOWN = "Unbekannter Befehl.",
	COMBAT_LOCKED = "Im Kampf nicht verfügbar.",

	-- BugLab probes
	PROBE_ENV = "Umgebung",
	PROBE_ENV_DESC = "Zeigt, welche Client-Funktionen Binds erkannt hat.",
	PROBE_SCAN = "Belegungen neu lesen",
	PROBE_SCAN_DESC = "Baut den Belegungs-Cache neu auf und zählt die Treffer.",
	PROBE_LOOKUP = "Belegungen einer Aktion",
	PROBE_LOOKUP_DESC = "Zeigt, was der Tooltip für einen Zauber, Gegenstand oder ein Makro anzeigen würde.",
	PROBE_KEY = "Taste einordnen",
	PROBE_KEY_DESC = "Kategorie und Anzeigetext einer Taste wie CTRL-BUTTON4.",
	PROBE_CLICKCASTS = "Klickzauber",
	PROBE_CLICKCASTS_DESC = "Listet Blizzards Klickzauber so, wie Binds sie liest.",
	PROBE_PARAM_KIND = "Art",
	PROBE_PARAM_ID = "ID",
	PROBE_PARAM_KEY = "Taste",
}
