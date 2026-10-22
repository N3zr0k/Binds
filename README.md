![Binds – Tastatur, Maus, Klickzauber](documentation/assets/Binds_Header_Light_NewLogo_1920x480.png)

[![Version](https://img.shields.io/github/v/release/N3zr0k/Binds?include_prereleases&label=Version&color=CBB9A5&labelColor=72645C&style=flat-square)](https://github.com/N3zr0k/Binds/releases)
[![Lint](https://img.shields.io/github/actions/workflow/status/N3zr0k/Binds/lint.yml?label=Lint&color=CBB9A5&labelColor=72645C&style=flat-square)](https://github.com/N3zr0k/Binds/actions/workflows/lint.yml)
![WoW Retail](https://img.shields.io/badge/WoW%20Retail-12.1.5-CBB9A5?labelColor=72645C&style=flat-square)
![WoW Forever](https://img.shields.io/badge/WoW%20Forever-16001-CBB9A5?labelColor=72645C&style=flat-square)
![Sprachen](https://img.shields.io/badge/Sprachen-deDE%20%7C%20enUS%20%7C%20frFR-E6D2B9?labelColor=72645C&style=flat-square)
![Abhängigkeiten](https://img.shields.io/badge/Abh%C3%A4ngigkeiten-keine-E6D2B9?labelColor=72645C&style=flat-square)
[![Lizenz](https://img.shields.io/badge/Lizenz-All%20rights%20reserved-ADA09A?labelColor=72645C&style=flat-square)](LICENSE)

# Binds

**Binds** zeigt dir direkt im Tooltip, wie du einen Zauber, Gegenstand oder ein Makro auslöst: über welche Taste, welche Maustaste oder welche Klickzauber-Kombination. Kein Suchen mehr in Aktionsleisten, Makrofenster oder Tastaturbelegung.

Binds **liest** Belegungen nur aus dem Spiel und **ändert** nichts: keine Tastenbelegungen, keine Makros, keine Aktionsleisten. Einzige Ausnahme ist die optionale Mouseover-Funktion für Klickzauber in WoW Forever (standardmäßig aus, siehe unten).

> Status: `0.1.16-beta.1` – Beta. Belegungen werden aus Aktionsleisten, Haltungsleiste, direkt belegten Makros und Klickzaubern gelesen; Ingame-Test läuft.

## Funktionen

- **Tooltip-Abschnitt** mit Binds-Kopfzeile in Zauber-, Gegenstands- und Makro-Tooltips.
- **Drei Kategorien**, farblich getrennt und mit eigenem Symbol:
  - Tastatur (z. B. `UMSCHALT + 1`)
  - Maus (z. B. `STRG + Maustaste 4`; Maus mit Modifikator bleibt Maus)
  - Klickzauber (Blizzards integriertes Click-Casting)
- **Datenquellen:** Aktionsleisten, Gestalt-/Haltungsleiste, direkt belegte Makros, Blizzard-Klickzauber. Kein weiteres Addon nötig.
- **Klickzauber im Einheiten-Tooltip:** Auf freundlichen Einheiten, z. B. Spielerframes, listet der Tooltip die Klickzauber, die du dort wirken kannst (Heilungen, Entzauberungen). Es erscheinen alle passenden Klickzauber; der optionale Modifikator-Filter entscheidet wie bei den anderen Tooltips, ob etwas angezeigt wird. Abschaltbar in den Optionen.
- **Automatische Aktualisierung**, sobald sich Belegungen, Makros, Leisten oder die Gestalt ändern.
- **Optionaler Modifikator-Filter:** Abschnitt nur anzeigen, solange Umschalt, Strg und/oder Alt gedrückt ist.
- **Optional, nur WoW Forever: Mouseover-Zauber in der Spielwelt** (standardmäßig aus): Blizzard-Klickzauber mit Modifikator, z. B. Umschalt + Rechtsklick, wirken auch auf Einheiten in der Spielwelt. Das Click-Casting-Profil selbst bleibt unverändert, einfache Klicks bleiben unberührt, Änderungen greifen außerhalb des Kampfes.
- **Titan Panel, Minimap-Symbol und Addon-Compartment:**
  - Rechtsklick: Binds-Optionen
  - Umschalt + Linksklick: Klickzauber-Einstellungen
  - Umschalt + Rechtsklick: Tastaturbelegung
  - Mouseover: Liste aller eingerichteten Klickzauber

- **BugLab-Anbindung (optional):** Debug-Ausgabe und Diagnose-Probes, wenn BugLab installiert ist.

## Unterstützte Clients

| Client | Interface |
| --- | --- |
| WoW Retail 12.1.5 | 120105 |
| WoW Forever | 16001 |

Beide Clients nutzen dieselbe TOC (`## Interface: 120105, 16001`). Funktionen, die es in einem Client nicht gibt (z. B. Klickzauber oder Addon-Compartment), blendet Binds dort aus, statt Fehler zu werfen.

Sprachen: Deutsch, Englisch, Französisch. Fehlt ein Text, wird Englisch verwendet.

## Installation

1. Ordner `Binds` nach `World of Warcraft\<Client>\Interface\AddOns\` kopieren.
2. Spiel starten bzw. `/reload`.

Alle Libraries (LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0) sind eingebettet; es muss nichts zusätzlich installiert werden.

## Bedienung

| Befehl | Wirkung |
| --- | --- |
| `/binds` | Optionen öffnen |
| `/binds minimap` | Minimap-Symbol ein- oder ausblenden |

Die Optionen findest du unter *Einstellungen → AddOns → Binds*: Die Seite **Binds** zeigt Version und Kurzinfo, alle Einstellungen liegen in der Unterkategorie **Allgemein**.

Gespeichert werden nur Einstellungen, immer kontoweit für alle Charaktere (`BindsDB`). Erkannte Belegungen werden nie gespeichert, sondern immer live aus dem Spiel gelesen.

## Grenzen

- Makros werden nicht textlich analysiert. Zugeordnet wird, was das Spiel für ein Makro gerade als Zauber oder Gegenstand meldet.
- Gamepad-Belegungen werden in Version 1 nicht angezeigt.
- Getestet wird in der WoW-Forever-Beta bis Stufe 30.

## Farbschema

| Rolle | Farbe |
| --- | --- |
| Hauptfarbe | `#CBB9A5` |
| Akzentfarbe | `#E6D2B9` |
| Neutral hell | `#F0EAE6` |
| Neutral dunkel | `#ADA09A` |
| Dunkles Taupe (Logo-Schrift) | `#72645C` |

## Für Entwickler

Aufbau, Modulsystem und API: [documentation/DEVELOPER.md](documentation/DEVELOPER.md) und [documentation/API.md](documentation/API.md).

## Lizenz und Danksagung

© 2026 N3zr0k – All rights reserved. Kopieren, Verändern oder Weiterverbreiten nur mit Erlaubnis des Autors, siehe [LICENSE](LICENSE).

- Symbole basieren auf [Lucide](https://lucide.dev) (ISC-Lizenz); SVG-Quellen unter `documentation/assets/icons/`.
- Eingebundene Libraries: LibStub (Public Domain), CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0 – jeweils unter ihren eigenen Lizenzen.
