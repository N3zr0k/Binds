# Binds – API

Globales Objekt: `Binds` (Stand `1.1.8-latest.1`, kann sich bis zur Beta ändern).

## Kern

| Funktion | Beschreibung |
| --- | --- |
| `Binds:RegisterModule(name, table?)` | Registriert ein Modul und gibt es zurück. Name muss eindeutig sein. |
| `Binds:GetModule(name)` | Gibt ein Modul zurück oder `nil`. |
| `Binds:RegisterModuleEvent(module, event, method?)` | Leitet ein WoW-Event an `module[method]` (Standard: Eventname). Unbekannte Events werden ignoriert. |
| `Binds:On(message, module, method?)` | Hört auf eine interne Nachricht. |
| `Binds:Fire(message, ...)` | Sendet eine interne Nachricht. |
| `Binds:Print(...)` | Chat-Ausgabe mit Addon-Präfix. |
| `Binds:Debug(fmt, ...)` | Wie `string.format`; nur bei aktivierter Debug-Option. Geht an BugLab, sonst in den Chat. |
| `Binds:GetLogger(module?)` | BugLab-Logger für `Binds` bzw. `Binds:<module>`, oder `nil` ohne BugLab. |
| `Binds:Colorize(text, key)` | Färbt Text mit einer Palettenfarbe (`primary`, `accent`, `neutralLight`, `neutralDark`, `taupe`) oder Kategorie (`keyboard`, `mouse`, `click`). |
| `Binds:OpenOptions()` | Öffnet die Einstellungen (nicht im Kampf). |

Felder: `Binds.version`, `Binds.title`, `Binds.author` (aus der TOC), `Binds.colors`, `Binds.categoryColors` (Tastatur #66BBFF, Maus #FFB454, Klickzauber #D6A4FF), `Binds.categoryLightColors` (aufgehellte Varianten für die Belegung), `Binds.db` (aktive Einstellungen).

## Interne Nachrichten

| Nachricht | Wann |
| --- | --- |
| `BindingsChanged` | Ein relevantes Event hat den Belegungs-Cache ungültig gemacht. |
| `SettingsChanged` | Eine Einstellung wurde in den Optionen geändert. |

## Scanner

| Funktion | Beschreibung |
| --- | --- |
| `Scanner:Get(kind, id)` | Belegungen für `kind` (`"spell"`, `"item"`, `"macro"`) und ID: `{ keyboard = {...}, mouse = {...}, click = {...} }` oder `nil`. |
| `Scanner:Classify(key)` | `"keyboard"`, `"mouse"` oder `nil` (Gamepad). |
| `Scanner:FormatKey(key)` | Lokalisierte Darstellung, z. B. `"STRG + Maustaste 4"`. |
| `Scanner:GetAll()` | Gesamter Cache (nur für Diagnose). |
| `Scanner:GetClickCasts()` | Liste `{ binding, name }` aller Blizzard-Klickzauber. |
| `Scanner:IsClickCastingAvailable()` | `true`, wenn der Client Blizzard-Klickzauber kennt. |
| `Scanner.Add(result, kind, id, category, text)` | Hilfsfunktion für Quellen; führt Duplikate zusammen und gibt den Eintrag zurück. |
| `Scanner:GetModifierSpellClicks()` | Liste `{ binding, spellID }` der Zauber-Klickzauber mit Modifikator (nur diese können einen zweiten Zauber haben). |
| `Scanner:GetSecondCasts(side)` | Aktive zweite Zauber als `{ binding, name, spellID }`; `side` ist `"friend"` oder `"enemy"` (Einheit, auf die der zweite Zauber wirkt). |

Einträge von `Scanner:Get` für Klickzauber mit zweitem Zauber tragen zusätzlich `clickPairs[bindingText] = { first, second }`.

## ClickSpells

Regeln für zweiten Zauber und Wiederbelebung; alles wirkt nur, solange `Binds.db.mouseoverCasts` an ist.

| Funktion | Beschreibung |
| --- | --- |
| `ClickSpells:Orientation(spellID)` | `"help"`, `"harm"`, `"both"` oder `nil` (wirkt auf Freunde, Feinde, beide, keins). |
| `ClickSpells:Conflicts(first, second)` | `true`, wenn beide Zauber dieselbe Einheitenart nehmen (zwei freundliche oder zwei feindliche): das Paar ist inaktiv, bleibt aber gespeichert. |
| `ClickSpells:GetStoredSecond(first)` / `GetSecond(first)` | Gespeicherter bzw. wirksamer zweiter Zauber. |
| `ClickSpells:GetCandidates(first)` | Liste `{ spellID, name, conflict }` der bekannten, aktiven Zauber im Zauberbuch; `conflict` markiert Zauber derselben Art wie `first`. |
| `ClickSpells:SetSecond(first, second)` | Setzt oder (mit `nil`) löscht den zweiten Zauber; gibt `true, inaktiv` oder `false` (Zauber unbekannt) zurück. |
| `ClickSpells:FirstBranch(first, second)` / `SecondSide(first, second)` | Welche Einheitenart der erste Zauber nimmt (`"help"`/`"harm"`) bzw. der zweite (`"friend"`/`"enemy"`). |
| `ClickSpells:GetAvailableResurrections()` | Bekannte Wiederbelebung `normal, combat` (je ggf. `nil`). |
| `ClickSpells:GetResurrection()` | Wirksame Wiederbelebung `spellID, name` oder `nil`. |
| `ClickSpells:Name(spellID)`, `GetTexture(spellID)`, `IconString(spellID, size?)` | Name, Symbol-Textur, Inline-Textur für Tooltips. |
