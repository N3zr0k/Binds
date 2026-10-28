# Changelog

## 1.2.23-beta.2
- Repo only: `.luacheckrc` knows the new globals (`StaticPopupDialogs` as an own global, `MenuUtil`, `BackdropTemplateMixin`, `ChatFontNormal`, `GameFontHighlight`, `UnitFullName`, `UnitName`, `C_TooltipInfo`), so the lint run is clean again.

## 1.2.23-beta.1
- Fixed: Shift + left-click on the minimap button, Titan Panel and addon compartment still called the plain open function (the change announced for 1.2.11 never reached the click handler). It now closes the options window first like the click cast icon does, then opens Blizzard's click casting window.

## 1.2.22-beta.1
- Debug output now also logs every click on the minimap button, Titan Panel and compartment (button, Shift, combat).
- If Blizzard's click casting window still does not come up after the second try (Shift + left-click on the minimap button, Titan Panel, compartment or the click cast icon), Binds prints one chat line saying what the game offers (function present, window present, options window closed), to find the cause.
- The check "is the click casting window already open" uses IsVisible instead of IsShown: the window is a child of the spellbook and can report "shown" while its parent is closed, which would have kept Binds from opening it.

## 1.2.21-beta.1
- Shift + left-click on the minimap button, Titan Panel and addon compartment now runs the very same function as Shift + left-click on the click cast icon on the Click Casting page. It opens Blizzard's click casting window only if it is not already open (the game's own function toggles), and tries once more if the first try did not bring it up.

## 1.2.20-beta.1
- Click Casting page: a combat resurrection item that was configured stays shown in the "In combat" field, greyed out, when it is missing from the bags or cannot be used; the tooltip says so. The choice is kept and takes effect again once the item is back.

## 1.2.19-beta.1
- Combat resurrection items from the bags are checked for usability: the game's own check (level, class, profession such as Engineering) and the red requirement lines of the item tooltip. Unusable items are not offered and are not used by the macro; with "Show all spells" they are listed greyed out, and picking one prints why it cannot be used. If no usable item is found, the whole "In combat" line is greyed out and inert (no click, no hover effect, no tooltip).

## 1.2.18-beta.1
- New option "Descriptions below the options" (General, section Display, default on): it switches the grey explanation texts under the options on and off. Off, the explanation of an option shows as a tooltip while the mouse is over the option; the label is clickable then too. It applies to all pages.

## 1.2.17-beta.1
- Click Casting page: if the class has no combat resurrection and no suitable item is in the bags, the "In combat" field is greyed out, marked "(unavailable)" and inert; the note below the fields changes to match. It becomes usable again as soon as an item shows up in the bags.

## 1.2.16-beta.1
- Choice lists (second spell, combat resurrection) use the game's own menu on Retail (the same frame and scroll bar as Blizzard's settings dropdowns, scrolling when the list is long) with the spell or item tooltip on mouseover. It opens directly below the icon (an invisible dropdown button over the icon). Clients without that menu (Forever) keep Binds' own list, now with a tooltip-style frame and a scroll bar.

## 1.2.15-beta.1
- Click Casting page: hovering the arrows between the click cast and the second spell shows a legend of the arrow colors (friendly, hostile, buff, remove, empty) with a short description and what the left and right arrow point at.

## 1.2.14-beta.1
- Tooltip arrows are brighter: the colors are mixed half-way towards white, because the grey slider arrow art is only darkened by a tint (the options page cuts the arrow out of a plain color fill instead, which a tooltip text cannot do).

## 1.2.13-beta.1
- Backup: the text of a character export carries the character name (`BINDS1:character:Name-Realm:payload:check`), and the import confirmation shows it. Texts without a name (1.2.9 to 1.2.12) are still accepted.
- Backup: a successful import starts with a green check mark.
- The overview text on the Binds page now also mentions click casting, mouseover click casts, the second spell and resurrection.

## 1.2.12-beta.1
- Fixed: Shift + left-click on the minimap button or addon compartment did not open Blizzard's click casting window while the game's options window was open. The options window is now closed with Blizzard's own close method (then the generic ways), the game menu is closed too, and the click casting window opens 0.3 s later. A debug line (`click settings: closed windows = ...`) tells whether a window was closed.
- Backup page: the export and import fields are multi-line boxes with a border that grow with the text, so the whole backup text is visible.

## 1.2.11-beta.1
- The Click Casting settings shortcut of the minimap button, Titan Panel and addon compartment (Shift + left-click) closes the options window first and then opens Blizzard's click casting window, like the options page does.
- Click Casting page: the tooltip of the click cast icon shows "Click Casting settings - Shift + left-click" in the same two-colour style as the Binds overview tooltip; Shift + left-click on the icon opens the settings directly (a plain click does nothing; the extra choice menu is gone).

## 1.2.10-beta.1
- Backup: Blizzard's click casting bindings are now part of the "Account" export too (when "Include Blizzard click casting" is on), not only of the character export. After an import the status line says why Blizzard's click casts were not restored (none in the text, combat, rejected by Blizzard).

## 1.2.9-beta.1
- Fixed: importing a backup always said "not a Binds backup text". The text used "|" as separator, which WoW edit boxes treat as an escape character and change on copy and paste. The separator is now ":" (format `BINDS1:scope:payload:check`); texts exported with 1.2.8 must be exported again.

## 1.2.8-beta.1
- New options page "Backup" (next to General and Click Casting): export the Binds settings as a line of text and import them again. Scope "Account" covers all Binds settings; "Current character" covers what hangs on the character's spells (second spells, combat resurrection) and, optionally, Blizzard's own click casting bindings of that character (replaced on import, out of combat only).
- The backup text is plain data in Base64 with a check value, never executable code; on import only known settings of the right type are taken over, and a confirmation is asked first. Changing the mouseover main switch by an import asks for a reload.

## 1.2.7-beta.1
- Fixed: the "Blizzard: click casting settings" choice on the Click Casting page did nothing while the settings window was open. From the options page the settings window is closed first and Blizzard's click casting window is opened a moment later, with the same function as the minimap shortcut; the minimap shortcut itself is unchanged.
- Click Casting page: a click on the click cast icon of a row (left) opens a choice with Blizzard's click casting settings; the icon's tooltip says so.
- Fixed: the note under the resurrection fields still did not wrap (it lost its right anchor on refresh) and ran out of the window.
- Click Casting page: while "Mouseover casts in the world" is off, a cover with an explanation blocks the whole page, and switching the option asks whether to reload the interface now (menu entries cannot be removed while the game runs, the page disappears after the reload).
- Tooltip arrows use the same slider arrow texture as the Click Casting options (Retail atlas, tinted); the right arrow of a mirrored atlas (coordinates the other way round) was wrongly replaced by our own arrow head before. Our own arrow heads (Media/arrow_*) only stand in where the atlases are missing.

## 1.2.6-beta.1
- Fixed: the long text under the resurrection fields was cut off at the bottom of the Click Casting page; the page height is now measured after the text has wrapped (after every refresh), with some extra room.
- Tooltips: the two arrows of a spell pair are exactly 2 px apart (a transparent spacer picture, Media/spacer_32x32.tga).
- "Mouseover casts in the world" (General page) is now on by default and is the main switch for all extra click casting features: off, the mouseover casts, second spell, resurrection and unit frame handling are all inactive and the Click Casting page is not offered (after /reload). Existing settings keep their saved value.
- Arrows between the icons: the right arrow was missing in the options; both are now the game's left slider arrow (Retail atlas Minimal_SliderBar_Button_Left), the right one turned by half a circle, a little smaller. The tooltips use the right atlas when it exists and otherwise the left one mirrored.

## 1.2.5-beta.1
- Arrows between the icons: the original slider arrows of the game (Retail atlases Minimal_SliderBar_Button_Left/Right) in the options and, with their atlas texture and coordinates, in the tooltips; centered between the click cast and the second spell. In the options a color fill is masked by the arrow so the color stays bright; the tooltips tint the grey original, so the color is a bit darker there. Clients without the atlases use our own arrow heads (Media/arrow_*).
- Tooltip order: click casts are always listed without modifier first, then Shift, Ctrl, Alt, then the combinations (Shift+Ctrl, Shift+Alt, Ctrl+Alt, all three); within a group Left, Right, Middle, Button 4, Button 5. Applies to the Binds overview tooltip, the spell tooltips and the unit tooltips.

## 1.2.4-beta.1
- Tooltips: a spell pair shows the two icons with a colored left and right arrow between them (new Media/arrow_links_weiss_32x32.tga) instead of "/". The Binds overview tooltip (minimap icon, Titan Panel) lists spell click casts with their spell icon and the pair icons, like the spell tooltips (icons follow the "spell icons" option).
- The two arrows between the icons now sit side by side (left points to the click cast, right to the second spell) and use the left/right arrows of the game's sliders on Retail, tinted by spell kind; other clients keep the plain arrow.
- The choice lists (second spell, combat resurrection) show the game's own tooltip for the spell or item under the mouse.
- Icon boxes are 45x45, the size of an action button, instead of 32x32; rows and the resurrection fields are spaced accordingly.
- Icon boxes: the spell icons are drawn larger. The icon mask now keeps the proportions it has on a 45x45 action button instead of being squeezed to the 32x32 icon, which had shrunk the visible icon inside the frame.

## 1.2.3-beta.1
- The 32x32 icon boxes on the Click Casting page use the action button look of Retail (icon frame, round-cornered icon mask, empty-slot art, mouseover and pressed states, the Retail atlases scaled from 45x45). Clients without those atlases keep a plain thin frame; the Forever look is still to do.

## 1.2.2-beta.1
- Fixed: click casts on the unit frames and in the world stopped working in 1.2.x. The resurrection was moved into extra macro lines; it is back inside the single /cast line as in 1.1.8 (with a combat resurrection set up, the normal one is limited to out of combat and the combat one to combat). Debug output for frame clicks now also shows the held modifier keys.
- Combat resurrection: dragging does not work in the options window, so the slot's list now also offers items from the bags. They are found by their use effect: items whose effect text mentions resurrecting (English, German, French keywords), no item list is kept. "Show all spells" lists every item with a use effect. Replaces the drag and drop of 1.2.1.

## 1.2.1-beta.1
- Combat resurrection: engineering items are no longer taken from a built-in item list. Drag an item from the bags onto the slot instead (it counts while it is in the bags); a click still opens the list of the class's combat resurrection spells.

## 1.2.0-beta.1
- Click Casting page redesigned: the click cast and the second spell are 32x32 icons showing the game's own tooltip on mouseover; an empty second-spell slot shows a plus. Between the icons sit two arrows on top of each other (upper points to the click cast, lower to the second spell), colored by the spell: green friendly, red hostile, blue buff, purple debuff removal (fixed spell list). The page scrolls.
- Resurrection now tells combat from non-combat: out of combat the normal resurrection, in combat the combat resurrection. The in-combat one is picked from a list of class spells and engineering items in the bags (Convincingly Realistic Jumper Cables, Emergency Soul Link, Disposable Spectrophasic Reanimator, Unstable Temporal Time Shifter, each within its level cap); without a choice the first possible one is used. Replaces the "normal / in combat" check boxes.
- The resurrection tooltip row follows the combat state and shows item icons too.
- New icon Media/arrow_weiss_32x32.tga; new concept document documentation/CONCEPT_Bedingungszauber.md (condition spells, not built yet).

## 1.1.8-latest.1
- The General page scrolls, so the Developer section is no longer cut off at the bottom of the window.
- Click cast tooltips show only the two spell icons for a spell pair, without the name of the second spell.
- README and the CurseForge descriptions now cover the second-spell conflicts, the "Show all spells" option, unit frames and spell icons.

## 1.1.7-alpha.1
- New option "Show all spells" (Click Casting page, off by default): off, the second-spell list hides spells of the same kind as the first spell; on, they are listed greyed out.

## 1.1.6-alpha.1
- Second spell: every known spell can be picked again. Two spells of the same kind (two friendly or two hostile ones) stay selectable but are greyed out and do not act; a warning badge with a mouseover text and a chat hint show why. Replaces the strict spell-text check of 1.1.5.

## 1.1.5-alpha.1
- Second spell: the list and the check are now strict. A heal only accepts damage spells and the other way round. The kind comes from the game's friendly/hostile flag plus the spell text (English, German, French); buffs, dispels, crowd control and spells that act on friends and enemies alike get no counterpart and are not offered.

## 1.1.4-alpha.1
- Fixed: second spell and resurrection did nothing on Blizzard unit frames, because Blizzard runs a bound click cast before the frame's own attributes. A secure pre-click snippet now turns exactly the affected clicks into an unused virtual button (Button31 ...) that carries Binds' macro; the Blizzard click casting profile stays untouched.

## 1.1.3-alpha.1
- Debug output for the unit frame click casts: each click on a frame logs the secure type and macro that would run, and game error messages ("Invalid target" ...) are logged while debug is on.

## 1.1.2-alpha.1
- Options: the "Click Casting" page now sits on the same level as General, directly below Binds.
- New (experimental): second spell and resurrection also work on Blizzard's player, target, focus, party and raid frames, via click attributes set out of combat (new module UnitFrames, option "Also on Blizzard unit frames", on by default). Click casts without an extra stay with Blizzard.

## 1.1.1-alpha.1
- Second spell: the slot now opens a list of the spells in your spellbook that fit as counterpart (known, active, the opposite kind), instead of drag and drop, which was impossible with the spellbook and the options both needed open. Right-click still clears the slot.

## 1.1.0-alpha.1
- New options page "Click Casting" below General. It is only registered while "Mouseover casts in the world" is on (that option moved back to General); switching it needs a /reload.
- New: second spell for click casts with a modifier. Counterpart per click cast: a damage spell for a heal, a heal for a damage spell. It acts on enemies or friends respectively, on the same keys, through the mouseover macro.
- New: resurrection for dead group members (normal or combat variant, any click cast with a modifier), only offered when the class has a resurrection.
- New: spell icons in click cast tooltips (option under Tooltip); the spell tooltip shows both icons and the counterpart's name, enemy and dead-member tooltips list the second spells and the resurrection.
- New module ClickSpells (rules for second spell and resurrection); Scanner gets GetModifierSpellClicks and GetSecondCasts.

## 1.0.0-latest.1
- First stable version: includes everything from the 0.1.x alpha and beta versions.
- New stage "latest" in the version scheme: handled by the release workflow like a normal release (no beta label).

## 0.1.17-beta.1
- Mouseover casts now apply to Retail and WoW Forever alike (the Forever-only restriction was removed).

## 0.1.16-beta.1
- Fixed: Blizzard error "attempt to index local 'color' (a secret table value ...)" in tooltips. Binds no longer refreshes the tooltip when bindings change, and the modifier-filter refresh skips unit tooltips and combat.

## 0.1.15-beta.1
- New: tooltips of friendly units (player frames, world) list all click casts you can use on them, helpful spells such as heals and dispels. The modifier filter decides whether it is shown. Option "Click casts in unit tooltips" under Tooltip, on by default.
- TOC: Retail interface 120107 (12.1.7) removed again until that patch is live.
- Mouseover casts are WoW Forever only: the option is hidden and the module inactive in Retail, where click casts already work in the world.

## 0.1.14-beta.1
- Fixed: mouseover casts did nothing because the secure button only listened for the button release; it now registers both directions.

## 0.1.13-beta.1
- New optional module "Mouseover casts in the world" (Options > General > Click casting, off by default): Blizzard click casts with a modifier also work as mouseover casts on units in the game world. Plain clicks stay untouched; bindings are applied out of combat.

## 0.1.12-beta.1
- License changed from MIT to All rights reserved (LICENSE, TOC, README, CurseForge badges).
- TOC: CurseForge project ID 1757598 added, so the release workflow uploads beta and release builds to CurseForge.

## 0.1.11-beta.1
- Release workflow: packager now runs with the new tag as ref, so it no longer skips the build ("Found future tag"); clear error if no ZIP was created.
- New README and CurseForge header graphics with the new logo (Binds_Header_Light/Dark_NewLogo_1920x480, PNG + SVG); old Compact headers removed.
- Minimap icon enlarged from 13 to 18 px.

## 0.1.10-beta.1
- The dark Binds icon (dark cursor) is now used everywhere: minimap, TOC, options list, tooltip header and addon list.

## 0.1.9-beta.1
- Fixed: error "attempt to perform arithmetic on a secret number value" (WoW Forever) in the tooltip header line.
- New Binds icon (B with cursor) in 128, 64 and 32 px for minimap, TOC, options list and tooltip header; dark variant added as Media/Binds_Icon_dunkel_*.
- New Binds logo with text (Media/Binds_Icon_und_Schrift 128, 64 and 32 px), used on the options overview and next to the broker tooltip.

## 0.1.8-beta.1
- TOC: Retail interface 120105 (12.1.5) added; the addon was marked incompatible on the live Retail client.
- Options: keyboard, mouse and click casting can be switched on and off individually. The switches sit under "Show bindings in tooltips", with icon and category color, and are hidden while that option is off.

## 0.1.7-beta.1
- Options: the Binds entry in the AddOns category list shows the Binds icon and the name in the primary color #CBB9A5.
- Addon list: Binds in the primary color (TOC title); in WoW Forever the Binds icon is added in front at display time (Retail shows the TOC icon).

## 0.1.6-beta.1
- Addon list: Binds shown in the primary color #CBB9A5 (TOC title). In WoW Forever the Binds icon is added in front of the name; Retail already shows the TOC icon. The name used in-game is read from the title without color codes.

## 0.1.5-beta.1
- Broker tooltip: "List of configured click casts" subtitle shown in neutral light #F0EAE6.

## 0.1.4-beta.1
- Broker tooltip (minimap, Titan Panel, compartment): click casts moved to the bottom, under the Binds header line and a "List of configured click casts" subtitle in the click casting color.

## 0.1.4-alpha.1
- Tooltip: the bindings section now starts with the Binds icon and name, followed by a divider line like the option sections.

## 0.1.3-alpha.1
- Author set to N3zr0k (TOC, LICENSE).
- Options: section divider lines snapped to the pixel grid so all render 1 px.
- Scanner implemented: action bars (incl. pages, forms, extra button), stance bar, directly bound macros and Blizzard click casting; rebuilt lazily after binding, macro, bar and form events.
- New category colors: keyboard #66BBFF, mouse #FFB454, click casting #D6A4FF; bindings shown on the right in a lighter shade of the category color.
- Broker tooltip: click casts listed as action left, binding right; click hints in two colors (action left, mouse button right).

## 0.1.2-alpha.1
- Options redesigned: overview page plus a General subcategory with sections.
- Per-character profiles removed; settings are always account-wide.
- Minimap icon reduced to 13x13 px.
- Broker clicks: right-click opens options, Shift + left-click click casting, Shift + right-click key bindings.
- Broker tooltip: Binds logo to the left of the tooltip, version line, readable mouse button names, target/menu click actions named instead of showing IDs.

## 0.1.1-alpha.1
- Core, options and slash command files moved from the addon root into Core/.
- README and CurseForge descriptions with headers and badges.

## 0.1.0-alpha.1
- Initial repository skeleton: TOC for Retail and Forever, core, options, slash command, locales (deDE, enUS, frFR).
- Module structure for scanner, tooltip and broker (Titan Panel, minimap, addon compartment).
- Logo and category icons (keyboard, mouse, click casting).
- Optional BugLab integration: debug logger and diagnostic probes.
