-- Nachtrag v0.9 (spec.md AD v0.12.0), spec T61 Rest; Übergabe TK 13; spec.md TK v0.4 Abschnitt 7.
-- Startbestand der Sätze der Planungshilfe außerhalb der Vergütung: Reisekosten, Beitrag, Zahlungsgebühren, Klima,
-- Emissionsfaktoren und Grenzwerte. Werte aus prototyp-tourenkonzept.md 5.1–5.4 (Prüfliste Referat Touren offen);
-- flight_min_km = 1.000 km (Product Owner 26.10.2026). Gültig ab 01.01.2026 [OFFEN: echte Daten].
-- Idempotent, überschreibt nichts.

insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
select v.k, v.l, v.g::public.ad_rate_group, v.u, v.v, date '2026-01-01', v.s
  from (values
  -- Reisekosten
  ('rKm', 'PKW je km', 'travel', '€/km', 0.20, 'Reisekostenordnung 2023, Ziff. 9'),
  ('rUe', 'Übernachtung höchstens je Nacht', 'travel', '€', 70, 'Reisekostenordnung, Ziff. 2 (geändert 07.01.2025)'),
  ('rSH', 'Fahrtpauschale Sulzenauhütte', 'travel', '€', 240, 'Reisekostenordnung 2023, Ziff. 9'),
  ('rKSH', 'Fahrtpauschale Karl-Stein-Hütte', 'travel', '€', 60, 'Reisekostenordnung 2023, Ziff. 9'),
  -- Teilnahmebeitrag
  ('rNM', 'Aufschlag Nichtmitglieder', 'fee', '%', 30, 'Festlegung Referat Touren (Prototyp Tourenkonzept)'),
  ('rRund', 'Teilnahmebeitrag aufrunden auf', 'fee', '€', 5, 'Festlegung Referat Touren (Prototyp Tourenkonzept)'),
  ('rVat', 'MwSt. auf Zahlungsgebühren', 'fee', '%', 19, 'Annahme Prototyp Tourenkonzept (Yolawo: zzgl. MwSt.)'),
  -- Klima
  ('rCO2', 'Interner CO2-Preis', 'climate', '€/t', 140, 'DAV-Klimaschutzkonzept (Fassung HV 22.11.2025)'),
  ('rKmTag1', 'Leipziger Richtwert PKW-Entfernung erster Tag', 'climate', 'km', 150,
   'Festlegung Referat Touren (Prototyp Tourenkonzept), nicht verbindlich'),
  ('rKmTagN', 'Leipziger Richtwert PKW-Entfernung je weiterem Tag', 'climate', 'km', 100,
   'Festlegung Referat Touren (Prototyp Tourenkonzept), nicht verbindlich'),
  ('ef_rail_long', 'Emissionsfaktor Bahn Fernverkehr', 'climate', 'g je Personen-km', 26, 'Umweltbundesamt, TREMOD 2024'),
  ('ef_rail_regional', 'Emissionsfaktor Bahn Nahverkehr', 'climate', 'g je Personen-km', 44, 'Umweltbundesamt, TREMOD 2024'),
  ('ef_coach', 'Emissionsfaktor Fernbus / Reisebus', 'climate', 'g je Personen-km', 30,
   'Umweltbundesamt (Fernlinienbus); Reisebus Näherung'),
  ('ef_local_bus', 'Emissionsfaktor Linienbus Nahverkehr', 'climate', 'g je Personen-km', 90, 'Umweltbundesamt'),
  ('ef_tram', 'Emissionsfaktor Straßenbahn / U-Bahn', 'climate', 'g je Personen-km', 42, 'Umweltbundesamt'),
  ('ef_car', 'Emissionsfaktor PKW (Verbrenner)', 'climate', 'g je Fahrzeug-km', 230,
   'abgeleitet: Umweltbundesamt 164 g/Pkm × 1,4 Personen'),
  ('ef_ecar', 'Emissionsfaktor PKW (Elektro)', 'climate', 'g je Fahrzeug-km', 98,
   'abgeleitet: Umweltbundesamt 70 g/Pkm × 1,4 Personen'),
  ('ef_van', 'Emissionsfaktor Kleinbus / Sektionsbus', 'climate', 'g je Fahrzeug-km', 232,
   'Klima-Rechner der DAV-Sektion Köln'),
  ('ef_flight', 'Emissionsfaktor Flug', 'climate', 'g je Personen-km', 290,
   'Umweltbundesamt, Flug Inland (inkl. Nicht-CO2-Effekte)'),
  ('ef_bike', 'Emissionsfaktor Fahrrad / zu Fuß', 'climate', 'g je Personen-km', 0, 'Annahme Prototyp Tourenkonzept'),
  ('ef_stay_hut', 'Emissionsfaktor Übernachtung DAV-Hütte', 'climate', 'kg je Person und Nacht', 9.32,
   'Klima-Rechner der DAV-Sektion Köln'),
  ('ef_stay_self_catering', 'Emissionsfaktor Übernachtung Selbstversorgerhütte / Ferienwohnung', 'climate',
   'kg je Person und Nacht', 9.32, 'Annahme Prototyp Tourenkonzept (wie Hütte)'),
  ('ef_stay_hotel', 'Emissionsfaktor Übernachtung Pension / Hotel', 'climate', 'kg je Person und Nacht', 16.8,
   'Klima-Rechner der DAV-Sektion Köln'),
  ('ef_stay_camping', 'Emissionsfaktor Übernachtung Zelt / Camping', 'climate', 'kg je Person und Nacht', 4.5,
   'Klima-Rechner der DAV-Sektion Köln'),
  ('ef_food_overnight', 'Emissionsfaktor Verpflegung je Tag mit Übernachtung', 'climate', 'kg je Person und Tag', 4.7,
   'Klima-Rechner der DAV-Sektion Köln'),
  ('ef_food_day', 'Emissionsfaktor Verpflegung je Tag ohne Übernachtung', 'climate', 'kg je Person und Tag', 1.6,
   'Klima-Rechner der DAV-Sektion Köln'),
  -- Grenzwerte der Planung
  ('car_permit_km', 'PKW-Fahrt nur mit Genehmigung ab', 'threshold', 'km', 500, 'Reisekostenordnung, Ziff. 6'),
  ('flight_min_km', 'Flug unter dieser Entfernung ausgeschlossen', 'threshold', 'km', 1000,
   'DAV-Selbstverpflichtung; Product Owner 26.10.2026'),
  ('hut_hp_min', 'Hütte Übernachtung mit Halbpension, plausibel ab', 'threshold', '€', 45,
   'Annahme Prototyp Tourenkonzept (Hüttenpreise 2026)'),
  ('hut_hp_max', 'Hütte Übernachtung mit Halbpension, plausibel bis', 'threshold', '€', 90,
   'Annahme Prototyp Tourenkonzept (Hüttenpreise 2026)'),
  ('planning_lead_months', 'Planung möglichst Monate vor Beginn', 'threshold', 'Monate', 6,
   'Folien Tourenleitertreffen (Prototyp Tourenkonzept)')
  ) as v (k, l, g, u, v, s)
 where not exists (
   select 1 from public.ad_rates r where r.rate_key = v.k and r.valid_from = date '2026-01-01'
 );

-- Zahlungsgebühren (Yolawo, zzgl. MwSt.): Prozent, fester Betrag, aktiv
insert into public.ad_rates (rate_key, label, rate_group, unit, percent, fixed, active, valid_from, source)
select v.k, v.l, 'payment_fee', '% + €', v.p, v.f, v.a, date '2026-01-01',
       'Yolawo, Zahlmethoden (Prototyp Tourenkonzept, Oktober 2026)'
  from (values
  ('fee_sepa', 'Zahlungsgebühr SEPA-Lastschrift', 1.5, 0.35, true),
  ('fee_card', 'Zahlungsgebühr Kredit- / Debitkarte', 2.9, 0.25, true),
  ('fee_paypal', 'Zahlungsgebühr PayPal', 4.5, 0.58, true),
  ('fee_klarna', 'Zahlungsgebühr Klarna', 4.3, 0.35, false),
  ('fee_transfer', 'Zahlungsgebühr Überweisung (online)', 1.9, 0.35, false)
  ) as v (k, l, p, f, a)
 where not exists (
   select 1 from public.ad_rates r where r.rate_key = v.k and r.valid_from = date '2026-01-01'
 );
