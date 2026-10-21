# Binds – Entwickler-Doku

## Aufbau

```
Binds/
  Binds.toc          Metadaten, einzige Quelle für Version/Autor; lädt nur Binds.xml
  Binds.xml          Ladeliste: Libs, Locales, Core, Options, Commands, Module
  Libs.xml           alle Libraries; neue Libs nur hier eintragen
  Core/
    Core.lua         Addon-Objekt, Locale, Farben, Einstellungen, Events, Modulsystem
    Options.lua      Einstellungen: Hauptseite Binds + Unterkategorie Allgemein
    Commands.lua     /binds
  Modules/
    Scanner.lua      liest Belegungen, Cache nur im Speicher
    Tooltip.lua      Tooltip-Abschnitt
    Broker.lua       LibDataBroker, Minimap, Addon-Compartment
  Locales/           deDE, enUS, frFR
  Media/             eigene TGA-Symbole (Lucide-basiert)
```

## Ablauf

1. `ADDON_LOADED` → `Binds:OnInitialize()` lädt die Einstellungen und ruft `OnInitialize` jedes Moduls.
2. `PLAYER_LOGIN` → `Binds:OnEnable()` ruft `OnEnable` jedes Moduls.
3. Der Scanner markiert seinen Cache bei relevanten Events als veraltet und baut ihn erst beim nächsten Tooltip neu auf. Es gibt keine OnUpdate-Schleife.
4. Der Tooltip fragt `Scanner:Get(kind, id)` ab und rendert maximal einen Abschnitt pro Tooltip-Aufbau.

## Konventionen

- Im Addon-Wurzelordner liegen keine Lua-Dateien; Kern-Dateien gehören nach `Core/`.
- Keine Abhängigkeiten. Libraries werden eingebettet und mit `LibStub(name, true)` optional geladen.
- Clients werden über vorhandene APIs erkannt, nicht über Versionsnummern.
- Jede API, die es nicht in allen Clients gibt, wird vor dem Aufruf geprüft oder in `pcall` gekapselt.
- Neue Texte immer in `deDE`, `enUS` und `frFR`.
- Lint: `luacheck .` (Konfiguration in `.luacheckrc`).

## Eigenes Modul

Ein Modul ist eine Tabelle mit optionalen `OnInitialize` und `OnEnable`.

Intern (Datei in `Modules/`, Eintrag in `Modules/Modules.xml`):

```lua
local _, ns = ...
local MyModule = ns.Binds:RegisterModule("MyModule")

function MyModule:OnInitialize()
	ns.Binds:RegisterModuleEvent(self, "UPDATE_BINDINGS", "OnBindingsUpdated")
end
```

Extern als eigenes Addon (`## Dependencies: Binds` in dessen TOC):

```lua
local MyModule = Binds:RegisterModule("MyAddon")
```

Wird ein Modul nach dem Login registriert, ruft Binds `OnInitialize` und `OnEnable` sofort nach.

Details zu allen Funktionen: [API.md](API.md).

## BugLab (optional)

Binds nutzt BugLab, wenn es geladen ist (`## OptionalDeps: BugLab`), und läuft ohne BugLab unverändert.

- **Anmeldung und Stil:** Beim Login meldet sich Binds mit `log:Announce({ version, debug })` an. Der Logger trägt den Namen „Binds“ in der Hauptfarbe `#CBB9A5`; getrennte Werte (`a | b; c`) werden reihum in Haupt-, Akzent- und Neutralfarben eingefärbt.
- **Debug-Ausgabe:** `Binds:Debug(fmt, ...)` schreibt bei aktivierter Debug-Option über `BugLab:GetLogger("Binds")` ins Debug-Log. Ohne BugLab geht die Zeile in den Chat. Module holen sich mit `Binds:GetLogger("Scanner")` einen eigenen Logger (`Binds:Scanner`).
- **Probes** (`Modules/Probes.lua`, alle `mode = "once"`):

| Probe | Parameter | Zweck |
| --- | --- | --- |
| `env` | – | erkannte Client-Funktionen und Libraries |
| `scan` | – | Cache neu aufbauen, Treffer je Art zählen |
| `lookup` | `kind` (spell/item/macro), `id` | was der Tooltip für diese Aktion zeigen würde |
| `key` | `key` (z. B. `CTRL-BUTTON4`) | Kategorie und Anzeigetext einer Taste |
| `clickcasts` | – | Blizzard-Klickzauber, wie Binds sie liest |

Aufruf im Spiel z. B. `/buglab probe Binds lookup spell, 133`. Die Probes sind bewusst im Release enthalten, damit Nutzer sie für Fehlerberichte ausführen können. Log-Zeilen sind englisch (Entwickler-Ausgabe), Titel und Beschreibungen lokalisiert.
