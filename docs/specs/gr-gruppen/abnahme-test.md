# Abnahme-Test: Gruppen (GR)

Umsetzungsdatei zu T050 ([tasks.md](tasks.md)). Grundlage: [quickstart.md](quickstart.md) Abschnitt D 1–12. Stand: 26.10.2026.

## 1. Ergebnis

Abnahme vom Product Owner am 26.10.2026 als erfolgt erklärt (gemeinsam mit Anwesenheitserfassung und Finanzen). Die Schritte aus quickstart.md D 1–12 wurden nicht einzeln protokolliert.

## 2. Prüfungen

| Prüfung | Ergebnis |
|---|---|
| `db-tests` (pgTAP GR) | erledigt (grün auf `main`) |
| T051 `npm run lint` | erledigt (keine Fehler; nur Warnungen ohne Bezug zu GR) |
| T051 `npm run build` | erledigt |
| T051 Personendaten-Prüfung über `docs`, `scripts`, `supabase/seed.sql` | erledigt (keine IBAN außer der Beispiel-IBAN, keine fremden E-Mail-Adressen) |

## 3. Freischalten

| Punkt | Stand |
|---|---|
| Freigabe PO | erledigt (26.10.2026) |
| Migration gemergt | erledigt (`20261101000100_gr_ez_fi_available.sql`, PR #60) |
| Migration in TEST | erledigt (26.10.2026) |
| Migration in PROD | offen (Weg nach PROD: [OFFEN] O1, supabase/setup/README.md) |

## 4. Offen

- Import der bestehenden Gruppen (US-GR-16, T046–T049).
