# Binds – API

Globales Objekt: `Binds` (Stand `0.1.2-alpha.1`, kann sich bis zur Beta ändern).

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
| `Scanner.Add(result, kind, id, category, text)` | Hilfsfunktion für Quellen; führt Duplikate zusammen. |
