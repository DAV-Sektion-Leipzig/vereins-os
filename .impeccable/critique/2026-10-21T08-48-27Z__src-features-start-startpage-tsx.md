---
target: Startseite und Kopfzeile
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/ekd2/GitHub/vereins-os/src/features/start/StartPage.tsx"
target_fingerprint: "sha256:e6b8f71c8da596e9961d6974573d9ff78c6f6c9e6554235a37286a5aa9ba36b6"
target_path: /Users/ekd2/GitHub/vereins-os/src/features/start/StartPage.tsx
timestamp: 2026-10-21T08-48-27Z
slug: src-features-start-startpage-tsx
---
Method: dual-agent (A: Designbewertung · B: Detektor + Browser)

## Design Health Score
| # | Heuristik | Wert | Befund |
|---|---|---|---|
| 1 | Systemstatus | 2 | kein Lade-/Wartezustand bei Loadern |
| 2 | Realwelt | 3 | Kürzel „AD“ und Stufe „verwalten“ sind interner Jargon |
| 3 | Kontrolle | 3 | Fehlerzustand ohne Ausweg |
| 4 | Konsistenz | 2 | Kürzelkachel grün (Ein-Grün-Regel), Fehler ohne Symbol (Text-und-Symbol-Regel) |
| 5 | Fehlervermeidung | 3 | – |
| 6 | Wiedererkennen | 2 | gleiche Kürzelkacheln bei 9 Modulen |
| 7 | Effizienz | 2 | Grafik schiebt Module mobil nach unten |
| 8 | Ästhetik | 3 | ruhig, Grafik groß ohne Information |
| 9 | Fehlerbehebung | 1 | „Bitte versuche es erneut“ ohne Knopf |
| 10 | Hilfe | 2 | leerer Zustand nennt keinen Ansprechpartner |
| Gesamt | | 23/40 | |

## Priority Issues
- [P1] Fehlerzustand ohne Erneut-laden und ohne Symbol
- [P1] Kein Ladezustand (Loader blockieren)
- [P2] Willkommensgrafik groß und generisch
- [P2] Kürzelkacheln grün und schwer unterscheidbar
- [P2] Leerer Zustand ohne nächsten Schritt
- [P3] Schutzzone des Logos in der Kopfzeile nicht nachgemessen; Fokus am Logo-Link schwach

Detektor: 0 Befunde. Kein Überlauf bei 320/375/1280 px. Abmelden 28 px hoch (AA ok, unter 44 px).
