# Konzept: Bedingungszauber (ab 1.3.0, noch nicht gebaut)

Stand: Entwurf zu 1.2.0-beta.1. Ziel: Ein Klickzauber soll je nach Lage einen anderen Zauber wirken, nicht nur "Freund → Zauber A, Feind → Zauber B" wie beim zweiten Zauber.

## Idee

Zu jedem Klickzauber mit Modifikator gibt es eine kurze **Regelliste**. Jede Regel besteht aus einer **Bedingung** und einem **Zauber**. Binds baut daraus dieselbe Art Mouseover-Makro wie heute und prüft die Regeln von oben nach unten; die erste passende gewinnt. Steht keine Regel zu, wirkt der ursprüngliche Klickzauber.

Der zweite Zauber ist dann nur der Sonderfall "Bedingung: Ziel ist Feind (bzw. Freund)". Wiederbelebung ist der Sonderfall "Bedingung: Ziel ist tot und in meiner Gruppe".

## Bedingungen (Auswahl, jeweils ein Makro-Bedingungswort)

| Bedingung in der Oberfläche | Makro-Bedingung | Hinweis |
| --- | --- | --- |
| Ziel ist Freund / Feind | `help` / `harm` | gibt es schon (zweiter Zauber) |
| Ziel ist tot | `dead` / `nodead` | gibt es schon (Wiederbelebung) |
| Im Kampf / außerhalb | `combat` / `nocombat` | gibt es schon (Kampf-Wiederbelebung) |
| Ziel ist in Gruppe / Schlachtzug | `party` / `raid` | |
| Haltung / Gestalt | `form:n` / `stance:n` | Klassen mit Gestalten |
| Spezialisierung | `spec:n` | |
| Zauber bekannt | `known:ID` | Talente ein/aus |
| Umschalt / Strg / Alt gedrückt (zusätzlich) | `mod:shift` ... | ergibt weitere Tastenebenen |

Es werden nur Bedingungen angeboten, die die geschützte Makro-Engine selbst auswertet. Binds rechnet im Kampf nichts und braucht keine Werte, die das Spiel als "secret" liefert.

## Datenmodell

```lua
clicks.rules = {
  [spellID des Klickzaubers] = {
    { when = { "harm", "nodead" }, spell = 585 },
    { when = { "help", "dead", "party" }, spell = 2006 },
  },
}
```

Regeln werden pro Klickzauber gespeichert, global für alle Charaktere (wie alle Einstellungen). Beim Laden werden Regeln mit unbekannten Zaubern übersprungen, nicht gelöscht.

## Oberfläche

Auf der Seite *Klickzauber* hat jede Zeile hinter dem zweiten Zauber ein kleines "+": Es öffnet eine Zeile mit Bedingungs-Auswahl (Liste, wie bisher) und Zauber-Auswahl (32x32-Symbol, wie beim zweiten Zauber). Pfeile und Farben bleiben: jede Regel bekommt einen Pfeil in der Farbe der Zauberart (grün Freund, rot Feind, blau Buff, lila Entfernen). Widersprüchliche Regeln (zwei, die nie gleichzeitig zutreffen können, oder zwei Regeln mit gleicher Bedingung) bekommen das Warnsymbol, die spätere ist inaktiv.

## Umsetzung

1. `ClickSpells` bekommt `GetRules(first)`, `SetRules(first, rules)`, `RuleConflicts(a, b)`.
2. `MouseoverCast.SpellMacro` erzeugt statt der festen Zeilen eine Zeile pro Regel: `/cast [@mouseover,<Bedingungen>] Zauber`. Die Wiederbelebungszeilen bleiben davor.
3. `UnitFrames` übernimmt das Makro unverändert (gleicher Weg wie heute).
4. Tooltip: ein Eintrag je Regel, mit Symbol; Ziel-Tooltips zeigen nur Regeln, die auf die Einheit zutreffen können.
5. Optionsseite: Regelzeilen; Schalter "Regeln" unter dem Schalter für den zweiten Zauber.

## Grenzen

- Makro-Bedingungen sind fest vorgegeben; freie Lua-Bedingungen gibt es nicht.
- Regeln gelten nur für Klicks mit Modifikator (wie der zweite Zauber), einfache Klicks bleiben unberührt.
- Änderungen nur außerhalb des Kampfes, ausgewertet wird aber auch im Kampf.
- Die Zahl der Regeln pro Klickzauber wird begrenzt (Vorschlag: 4), damit der Makrotext übersichtlich bleibt.

## Offene Fragen an Sven

1. Sollen Regeln den zweiten Zauber ersetzen oder daneben stehen?
2. Welche Bedingungen sind dir am wichtigsten (Vorschlag für Version 1: Freund/Feind, tot, Kampf, Gruppe, Haltung)?
3. Soll es Vorlagen geben ("Heilen oder Schaden", "Entzaubern wenn Debuff")? Debuff-Erkennung ist im geschützten Makro nicht möglich; deshalb nur über den festen Zauberzweck.
