# Vorlagen – Vereins OS

Verbindliche Vorlagen für alle Module. Ablage pro Modul unter `docs/specs/<modul>/`.

## Vorlage 00-steckbrief.md

```
# Steckbrief: <Modulname>
**Problem heute:** <2–3 Sätze, ein konkretes Beispiel>
**Ziel / Erfolgsmessung:** <messbar>
**Nutzer & Rechtevorlagen:** <Rechtevorlage – Nutzungsart>
**Im Scope (MVP):**
- ...
**Nicht im Scope:**
- ...
**Abhängigkeiten:** <Modul – welche Daten, Richtung>
**Risiken / Besonderheiten:** <Datenschutz, externe Dienste, Kosten>
**Offene Fragen:**
- [OFFEN] ...
```

## Vorlage 01-erhebung.md

```
# Erhebung: <Modulname>
Datum: <TT.MM.JJJJ> · Beteiligte: <Namen/Rollen>
## A. Rechtevorlagen & Rechte
## B. Abläufe (inkl. Zustände)
## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)
## D. Regeln (R1, R2 …)
## E. Schnittstellen
## F. Datenschutz
## G. Nicht-funktional
## Offene Fragen (Frage | Wer klärt | bis wann)
```

## Vorlage User Story (für 02-stories.md)

```
### US-<Kürzel>-<Nr>: <Titel>
**Als** <Nutzer mit Rechtevorlage …>
**möchte ich** <Ziel>,
**damit** <Nutzen>.
**Priorität:** Must/Should/Could/Won't · **Regeln:** R… · **Abhängig von:** US-…
**Akzeptanzkriterien** (2–6, Given-When-Then, mind. 1 Fehlerfall + 1 Rechte-Fall)
- AK1: Gegeben …, wenn …, dann …
**Nicht Teil dieser Story:** …
```

## Vorlage spec.md

```
# Spec: <Modulname>
Version: 0.1 · Status: Entwurf | Ready | In Umsetzung | Fertig
Stories: docs/specs/<modul>/02-stories.md
## 1. Ziel und Scope (inkl. Nicht im Scope)
## 2. Datenmodell (Tabelle: Spalte | Typ | Pflicht | Default | Beschreibung; Beziehungen; Indizes)
## 3. Rechte / RLS (Rechtevorlage | Lesen | Anlegen | Ändern | Löschen)
## 4. Zustände und Übergänge (Von | Nach | Wer | Bedingung)
## 5. Geschäftsregeln (R1: Wenn …, dann …, sonst Fehlermeldung "…")
## 6. Screens und Interaktionen (Zeigt, Aktionen, leerer Zustand, Mobile)
## 7. Schnittstellen
## 8. Nicht-funktionale Anforderungen
## 9. Testdaten (5–10 fiktive Datensätze)
## 10. Umsetzungs-Tasks (- [ ] T1: … (US-…))
## 11. Annahmen und offene Punkte
```

## Anhang: Definition of Ready

Eine User Story ist umsetzungsbereit, wenn:

- [ ] Rechtevorlage, Ziel und Nutzen benannt
- [ ] Akzeptanzkriterien testbar im Given-When-Then-Format
- [ ] Fehlerfall und Rechte-Fall abgedeckt
- [ ] Alle Begriffe im Glossar
- [ ] Datenfelder im Datenmodell der Spec beschrieben
- [ ] Regeln per ID referenziert
- [ ] Keine [OFFEN]-Punkte mehr, Annahmen als [ANNAHME] sichtbar
- [ ] "Nicht Teil dieser Story" ausgefüllt
