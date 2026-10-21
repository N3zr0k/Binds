# Farbschema

| Rolle | Hex | Verwendung im Addon |
| --- | --- | --- |
| Hauptfarbe | `#CBB9A5` | Überschriften, Kategorie Tastatur |
| Akzentfarbe | `#E6D2B9` | Kategorie Maus |
| Neutral hell | `#F0EAE6` | Kategorie Klickzauber |
| Neutral dunkel | `#ADA09A` | Hinweise im Broker-Tooltip |
| Dunkles Taupe | `#72645C` | Logo-Schrift, Debug-Präfix |

Die Werte stehen in `Binds/Core/Core.lua` (`palette`). Die Kategorien haben eigene Farben in `Binds.categoryColors`: Tastatur #66BBFF, Maus #FFB454, Klickzauber #D6A4FF. Die Belegung rechts im Tooltip nutzt eine um 60 % aufgehellte Variante (`Binds.categoryLightColors`: #C2E4FF, #FFE1BB, #EFDBFF). In den Klick-Hinweisen steht die Taste in Neutral Hell #F0EAE6.
