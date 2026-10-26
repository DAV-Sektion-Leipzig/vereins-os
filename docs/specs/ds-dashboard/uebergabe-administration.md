# Übergabe: Dashboard → Administration

Stand: 26.10.2026 · Version 1.2 · Status: offen (Nachtrag der Administration vor der ersten Migration des Dashboards)
Änderungen v1.2: D10 neue Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz (Q-DS6, Product Owner 26.10.2026).
Änderungen v1.1: D3, D5, D6, D9 nach den Entscheidungen vom 26.10.2026 (Admin sieht Budget; Kennzeichen „darf Budget pflegen“; Gruppenleitungen ohne Budget).
Grundlage: specs/ds-dashboard/00-steckbrief.md v0.4 (Q-DS7, Q-DS8, Q-DS12, Q-DS13, Q-DS14, D5), uebergabe-finanzen.md v1.2, spec.md AD v0.10.0 (`ad_modules`, `ad_template_rights`, R30), rollen.md v1.3.

Kennzeichnung: **[ANNAHME]** = Vorschlag, mit dem Product Owner zu bestätigen. **[OFFEN]** = Entscheidung fehlt.

## Entscheidungen des Product Owners (26.10.2026)

- Die Budget-Sicht und die Referats-Sichten laufen über ein **eigenes Recht „Dashboard lesen“** (Modul DS). Ein Recht auf DS gibt keine Rechte in den Fachmodulen; die Lesefunktionen der Fachmodule für das Dashboard prüfen das Recht auf DS.
- Den DATEV-Export spielt der **1. Vorsitzende** ein und pflegt die Zuordnung, später die **Schatzmeister:in**; nicht die Geschäftsstelle.

## Anforderungen

| Nr | Anforderung | Vorschlag |
|---|---|---|
| D1 | **Modul DS** in `ad_modules` (Code `DS` [ANNAHME], Name „Dashboard“ (Q-DS10, entschieden 26.10.2026)). Für jede vorhandene Vorlage eine Zeile DS mit `none`, außer den Startwerten (wie T50/T59). | – |
| D2 | **Reichweite „Referat“ für DS** (R30: Check um `DS` erweitern). Stufen im MVP nur „lesen“; „bearbeiten“/„verwalten“ haben in DS keine Wirkung [ANNAHME]. | – |
| D3 | **Startwerte:** Admin – DS lesen (alle), mit Budget-Sicht (D5); Geschäftsstelle – DS lesen (alle); Referent:in – DS lesen (Referat); Vorstand – DS lesen (alle) [ANNAHME: Vorstand startet sonst ohne Rechte, rollen.md]. | Product Owner bestätigt |
| D4 | **Hilfsfunktionen** wie bei den anderen Modulen: `ad_has_level('DS', …)`, Referate der Zuweisung für DS (`ad_my_referate('DS')` o. ä.), damit Lesefunktionen in FI, GR, EZ, EA, TK die Reichweite prüfen können. | – |
| D5 | **Admin und Budget** (entschieden 26.10.2026): Der Admin sieht über „DS lesen“ auch die Budget-Sicht mit Einzelbuchungen, obwohl er keinen Zugriff auf Finanzen hat. Das gilt auch für den Notfall-Admin. rollen.md (Admin) ist entsprechend zu ergänzen. | entschieden |
| D6 | **Recht für die Budgetpflege** (Import, Zuordnung, Umschlüsseln). Der 1. Vorsitzende hat Admin, Admin hat kein FI. Entschieden 26.10.2026: **Kennzeichen „darf Budget pflegen“** (z. B. `can_maintain_budget`) an `ad_template_rights`, analog `can_approve`. Vorschlag [ANNAHME]: am Recht auf **DS** (Stufe mindestens „lesen“, Reichweite „alle“), damit kein Recht auf FI nötig ist; die Pflegefunktionen im Bereich Budget von FI prüfen `ad_has_budget_maintain()`. Startwert: neue Rechtevorlage „Budgetpflege“ (DS lesen + darf Budget pflegen), zugewiesen an den 1. Vorsitzenden; später an die Schatzmeister:in. | entschieden, Detail [ANNAHME] |
| D7 | **Startseite:** Für Nutzer mit DS-Recht zeigt die Startseite die passende Sicht statt der Willkommensgrafik; ohne DS-Recht bleibt die Startseite wie heute. | [ANNAHME] |
| D8 | **Testzugänge in TEST:** Referent:in Kinder und Jugend und Vorstand mit DS lesen; Testzugang „Budget“ (1. Vorsitzender) für die Pflege; fiktive Budgetdaten im Seed. | – |
| D9 | **Später:** Rechtevorlage Schatzmeister:in (FI-Vorlagen Q9) mit Budgetpflege; Reichweite „Gruppe“ für DS mit der Vorlage Gruppenleitung: Kennzahlen der eigenen Gruppe ohne Budget und Buchungen (Q-DS8, entschieden 26.10.2026). | – |
| D10 | **Neue Referate** (Q-DS6, entschieden 26.10.2026): „Öffentlichkeitsarbeit“ und „Umwelt und Naturschutz“ in `ea_referate` per Migration ergänzen (dann 9 Referate). Wirkt in allen Modulen mit Reichweite „Referat“ (EA, EZ, TK, FI, DS); Kennzeichen „halbjährliche Abrechnung“ = nein [ANNAHME]. Startbestand der Referate in spec.md AD, glossar.md und modul-landkarte.md anpassen. | entschieden |
