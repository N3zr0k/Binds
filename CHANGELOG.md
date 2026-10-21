# Changelog

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
