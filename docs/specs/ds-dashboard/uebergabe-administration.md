# Übergabe: Dashboard → Administration

Stand: 26.10.2026 · Version 1.0 · Status: offen (Nachtrag der Administration vor der ersten Migration des Dashboards)
Grundlage: specs/ds-dashboard/00-steckbrief.md v0.3 (Q-DS7, Q-DS12, Q-DS14), uebergabe-finanzen.md v1.1, spec.md AD v0.10.0 (`ad_modules`, `ad_template_rights`, R30), rollen.md v1.3.

Kennzeichnung: **[ANNAHME]** = Vorschlag, mit dem Product Owner zu bestätigen. **[OFFEN]** = Entscheidung fehlt.

## Entscheidungen des Product Owners (26.10.2026)

- Die Budget-Sicht und die Referats-Sichten laufen über ein **eigenes Recht „Dashboard lesen“** (Modul DS). Ein Recht auf DS gibt keine Rechte in den Fachmodulen; die Lesefunktionen der Fachmodule für das Dashboard prüfen das Recht auf DS.
- Den DATEV-Export spielt der **1. Vorsitzende** ein und pflegt die Zuordnung, später die **Schatzmeister:in**; nicht die Geschäftsstelle.

## Anforderungen

| Nr | Anforderung | Vorschlag |
|---|---|---|
| D1 | **Modul DS** in `ad_modules` (Code `DS` [ANNAHME], Name „Dashboard“ [OFFEN Q-DS10: Name in der Oberfläche]). Für jede vorhandene Vorlage eine Zeile DS mit `none`, außer den Startwerten (wie T50/T59). | – |
| D2 | **Reichweite „Referat“ für DS** (R30: Check um `DS` erweitern). Stufen im MVP nur „lesen“; „bearbeiten“/„verwalten“ haben in DS keine Wirkung [ANNAHME]. | – |
| D3 | **Startwerte:** Admin – DS lesen (alle) [ANNAHME: ohne Budget-Sicht, siehe D5]; Geschäftsstelle – DS lesen (alle); Referent:in – DS lesen (Referat); Vorstand – DS lesen (alle) [ANNAHME: Vorstand startet sonst ohne Rechte, rollen.md]. | Product Owner bestätigt |
| D4 | **Hilfsfunktionen** wie bei den anderen Modulen: `ad_has_level('DS', …)`, Referate der Zuweisung für DS (`ad_my_referate('DS')` o. ä.), damit Lesefunktionen in FI, GR, EZ, EA, TK die Reichweite prüfen können. | – |
| D5 | **Admin und Budget:** Der Admin hat keinen Zugriff auf Finanzen (rollen.md). [OFFEN] Sieht der Admin über „DS lesen“ die Budget-Sicht? Vorschlag: nein; die Budget-Lesefunktionen verlangen DS lesen **und** eine andere Vorlage als Admin allein (z. B. Vorstand). | [OFFEN] |
| D6 | **Recht für die Budgetpflege** (Import, Zuordnung, Umschlüsseln) [OFFEN Q-DS14]. Der 1. Vorsitzende hat Admin, Admin hat kein FI. Varianten: (a) neue Rechtevorlage „Budget“ mit Objekt „Budget“ in FI (Rechte je Objekt, rollen.md Abschnitt 2, bisher nach MVP), (b) Kennzeichen an der Zuweisung wie „darf freigeben“ (z. B. „darf Budget pflegen“), (c) FI verwalten (dann auch Abrechnungen und Bankdaten – widerspricht der Datensparsamkeit). Vorschlag: (b). | [OFFEN] |
| D7 | **Startseite:** Für Nutzer mit DS-Recht zeigt die Startseite die passende Sicht statt der Willkommensgrafik; ohne DS-Recht bleibt die Startseite wie heute. | [ANNAHME] |
| D8 | **Testzugänge in TEST:** Referent:in Kinder und Jugend und Vorstand mit DS lesen; Testzugang „Budget“ (1. Vorsitzender) für die Pflege; fiktive Budgetdaten im Seed. | – |
| D9 | **Später:** Rechtevorlage Schatzmeister:in (FI-Vorlagen Q9) mit Budgetpflege; Reichweite „Gruppe“ für DS mit der Vorlage Gruppenleitung [OFFEN Q-DS8]. | – |
