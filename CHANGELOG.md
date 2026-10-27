# Changelog

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
