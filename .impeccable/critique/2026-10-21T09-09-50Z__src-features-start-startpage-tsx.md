---
target: Startseite und Kopfzeile
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/ekd2/GitHub/vereins-os/src/features/start/StartPage.tsx"
target_fingerprint: "sha256:57adba099e065ad7b8ce01b019f1785bce42f75945c73f06e7d79229a8eb5e84"
target_path: /Users/ekd2/GitHub/vereins-os/src/features/start/StartPage.tsx
timestamp: 2026-10-21T09-09-50Z
slug: src-features-start-startpage-tsx
---
Method: dual-agent (A: Designbewertung · B: Detektor + Messung per CDP)

## Design Health Score
| # | Heuristik | Wert | Befund |
|---|---|---|---|
| 1 | Systemstatus | 3 | Ladezustände vorhanden; „Erneut laden“ jetzt mit „Wird geladen …“ |
| 2 | Realwelt | 4 | Glossar-Begriffe, du-Ansprache |
| 3 | Kontrolle | 3 | mobil im Modul nur Logo als Weg zurück |
| 4 | Konsistenz | 3 | „Passwort vergessen“ nicht als Link nach DESIGN.md gestaltet |
| 5 | Fehlervermeidung | 3 | – |
| 6 | Wiedererkennen | 3 | Unterscheidbarkeit der Module als Merkposten |
| 7 | Effizienz | 2 | kein Direkteinstieg bei nur einem Modul |
| 8 | Ästhetik | 3 | Desktop-Grafik dominiert bei einer Kachel |
| 9 | Fehlerbehebung | 3 | Login-Fehler nicht mit Feldern verknüpft |
| 10 | Hilfe | 2 | „den Admin“ ohne Kontakt |
| Gesamt | | 29/40 | |

## Priority Issues
- [P2] Leerer Zustand ohne konkreten Kontakt (fachliche Entscheidung)
- [P2] Login-Fehler: aria-invalid/aria-describedby fehlen (h1 ergänzt)
- [P3] „Passwort vergessen“ nicht in Mittelgrün dunkel
- Behoben in diesem Lauf: Fokus am Logo-Link war unsichtbar (outline-none in Tailwind v4)

Detektor: 0 Befunde. Messung: Schutzzone Kopfzeile 24 px (Soll 23,9), Anmeldung 56 px (Soll 50,4), Abmelden 32 px, kein Überlauf bei 320/375/1280 px.
