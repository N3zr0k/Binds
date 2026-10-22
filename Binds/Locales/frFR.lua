local _, ns = ...
ns.Locales = ns.Locales or {}

ns.Locales.frFR = {
	CATEGORY_KEYBOARD = "Clavier",
	CATEGORY_MOUSE = "Souris",
	CATEGORY_CLICK = "Sorts au clic",

	CATEGORY_GENERAL = "Général",

	OVERVIEW_TEXT = "Binds affiche dans l'infobulle comment déclencher un sort, un objet ou une macro. Les raccourcis sont seulement lus, jamais modifiés.",
	VERSION = "Version",
	AUTHOR = "Auteur",

	OPT_SHOW_TOOLTIP = "Afficher les raccourcis dans les infobulles",
	OPT_MODIFIER_FILTER = "Afficher seulement si une touche de modification est enfoncée",
	OPT_MODIFIER_SHIFT = "Maj",
	OPT_MODIFIER_CTRL = "Ctrl",
	OPT_MODIFIER_ALT = "Alt",
	OPT_MINIMAP = "Afficher le bouton de la minicarte",
	OPT_DEBUG = "Sortie de débogage",

	-- Options layout
	GENERAL_SUBTITLE = "Les réglages s'appliquent à tous les personnages du compte.",
	SECTION_TOOLTIP = "Infobulle",
	SECTION_CLICKCAST = "Sorts au clic",
	OPT_MOUSEOVER = "Sorts « mouseover » dans le monde",
	OPT_MOUSEOVER_DESC = "Les sorts au clic avec modificateur (p. ex. Maj + clic droit) fonctionnent aussi sur les unités du monde, en mouseover. Les réglages restent ceux de Blizzard. Les clics simples ne sont pas affectés ; les changements s’appliquent hors combat.",
	SECTION_MINIMAP = "Minicarte et Titan Panel",
	SECTION_DEVELOPER = "Développeur",
	OPT_SHOW_TOOLTIP_DESC = "Ajoute une section Binds aux infobulles des sorts, objets et macros.",
	OPT_CATEGORY_KEYBOARD_DESC = "Raccourcis clavier, p. ex. 1 ou Maj + F.",
	OPT_CATEGORY_MOUSE_DESC = "Boutons et molette de la souris liés à l’action.",
	OPT_CATEGORY_CLICK_DESC = "Sorts au clic de Blizzard sur les cadres d’unité.",
	OPT_UNIT_CLICKCASTS = "Sorts au clic dans les infobulles d’unités",
	OPT_UNIT_CLICKCASTS_DESC = "Affiche sur les unités amicales, p. ex. les cadres de joueur, les sorts au clic utilisables (soins, dissipations).",
	OPT_MODIFIER_FILTER_DESC = "La section apparaît dès qu'une des touches choisies est enfoncée.",
	OPT_MINIMAP_DESC = "Titan Panel et le compartiment d'addons ne sont pas concernés.",
	OPT_DEBUG_DESC = "Écrit les lignes de débogage dans BugLab, ou dans le chat sans BugLab.",
	OVERVIEW_HINT = "Tous les réglages se trouvent dans la catégorie Général.",

	HINT_OPTIONS = "Options de Binds",
	HINT_CLICKCAST = "Réglages des sorts au clic",
	HINT_KEYBINDS = "Raccourcis clavier",
	CLICK_RIGHT = "Clic droit",
	CLICK_SHIFT_LEFT = "Maj + clic gauche",
	CLICK_SHIFT_RIGHT = "Maj + clic droit",
	CLICK_ACTION_TARGET = "Cibler",
	CLICK_ACTION_MENU = "Ouvrir le menu",
	CLICK_ACTION_UNKNOWN = "Action inconnue",
	BROKER_CLICKCAST_LIST = "Liste des sorts au clic configurés",
	BROKER_NO_CLICKCASTS = "Aucun sort au clic configuré.",
	BROKER_CLICKCAST_UNAVAILABLE = "Les sorts au clic ne sont pas disponibles dans ce client.",

	CMD_HELP = "Commandes : /binds (options), /binds minimap (afficher/masquer le bouton)",
	CMD_UNKNOWN = "Commande inconnue.",
	COMBAT_LOCKED = "Indisponible en combat.",

	-- BugLab probes
	PROBE_ENV = "Environnement",
	PROBE_ENV_DESC = "Affiche les fonctions du client détectées par Binds.",
	PROBE_SCAN = "Relire les raccourcis",
	PROBE_SCAN_DESC = "Reconstruit le cache des raccourcis et compte les résultats.",
	PROBE_LOOKUP = "Raccourcis d'une action",
	PROBE_LOOKUP_DESC = "Affiche ce que l'infobulle montrerait pour un sort, un objet ou une macro.",
	PROBE_KEY = "Classer une touche",
	PROBE_KEY_DESC = "Catégorie et texte affiché d'une touche comme CTRL-BUTTON4.",
	PROBE_CLICKCASTS = "Sorts au clic",
	PROBE_CLICKCASTS_DESC = "Liste les sorts au clic de Blizzard tels que Binds les lit.",
	PROBE_PARAM_KIND = "Type",
	PROBE_PARAM_ID = "ID",
	PROBE_PARAM_KEY = "Touche",
}
