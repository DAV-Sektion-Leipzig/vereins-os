-- US-AD-18, spec T27: Startbestand 47 Qualifikationsarten aus
-- docs/specs/ea-ehrenamt/stammdaten-qualifikationsarten.md v0.2, Abschnitt 3.
-- Idempotent über source_ref; Änderungen aus der Oberfläche werden nie überschrieben. Keine Personendaten.
-- Abbildung: Stufe V → pre, – bei Lizenz → none; DOSB ja/nein, sonst null; Status mit [ANNAHME] wie genannt;
-- PSA mit Status historic, bis der Product Owner entscheidet (spec.md Abschnitt 2); Aussteller [OFFEN] bleibt sichtbar.

insert into public.ad_qualification_types
  (source_ref, code, name, discipline, kind, level, specification, issuer, dosb_eligible, validity_years, status, note)
values
  -- 3.1 Klettersport
  ('2325', 'KB', 'Kletterbetreuer*in Breitensport', 'Klettersport', 'license', 'pre', 'Sportklettern Breitensport', 'Bundesverband', false, 4, 'current', 'R3-Ausnahme'),
  ('20635', 'TCSPI', 'Trainer*in C Sportklettern Breitensport Indoor', 'Klettersport', 'license', 'C', 'Sportklettern Breitensport Indoor', 'Bundesverband', true, 4, 'current', null),
  ('2317', 'TCBO', 'Trainer*in C Bouldern Breitensport Indoor', 'Klettersport', 'license', 'C', 'Bouldern Breitensport Indoor', 'Bundesverband', true, 4, 'current', null),
  ('2318', 'TCLS', 'Trainer*in C Sportklettern Leistungssport', 'Klettersport', 'license', 'C', 'Sportklettern Leistungssport', 'Bundesverband', true, 4, 'current', null),
  ('2315', 'TCBM', 'Trainer*in C Klettern für Menschen mit Behinderungen', 'Klettersport', 'license', 'C', 'Klettern für Menschen mit Behinderungen', 'Bundesverband', true, 4, 'current', null),
  ('2314', 'TBSP', 'Trainer*in B Sportklettern Breitensport', 'Klettersport', 'license', 'B', 'Sportklettern Breitensport', 'Bundesverband', true, 4, 'current', null),
  ('2313', 'TBLS', 'Trainer*in B Sportklettern Leistungssport', 'Klettersport', 'license', 'B', 'Sportklettern Leistungssport', 'Bundesverband', true, 4, 'current', null),
  ('19937', 'TALS', 'Trainer*in A Sportklettern Leistungssport', 'Klettersport', 'license', 'A', 'Sportklettern Leistungssport', 'Bundesverband', true, 2, 'current', null),
  ('2319', 'RB', 'Routenbauer*in Breitensport', 'Klettersport', 'license', 'none', 'Routenbau Breitensport', 'Bundesverband', false, 4, 'current', null),
  ('2321', 'ZQOS', 'Zusatzqualifikation Sportklettern Outdoor', 'Klettersport', 'add_on', null, 'Sportklettern Outdoor', 'Bundesverband', null, null, 'current', 'kein eigenes Ablaufdatum [ANNAHME]'),
  ('2322', 'ZQOB', 'Zusatzqualifikation Bouldern Outdoor', 'Klettersport', 'add_on', null, 'Bouldern Outdoor', 'Bundesverband', null, null, 'current', 'wie ZQOS'),
  ('2320', 'ZQTD', 'Zusatzqualifikation Traditionelles Klettern', 'Klettersport', 'add_on', null, 'Traditionelles Klettern', 'Bundesverband', null, null, 'current', 'wie ZQOS'),
  ('2316', 'TCSP', 'Trainer*in C Sportklettern Breitensport (bis 2018)', 'Klettersport', 'license', 'C', 'Sportklettern Breitensport', 'Bundesverband', true, 4, 'historic', null),
  ('20634', 'KS', 'Trainer*in C Sportklettern Breitensport (alt)', 'Klettersport', 'license', 'C', 'Sportklettern Breitensport', 'Bundesverband', true, 4, 'historic', null),
  ('20633', 'TC', 'Trainer*in C Sportklettern Leistungssport (alt)', 'Klettersport', 'license', 'C', 'Sportklettern Leistungssport', 'Bundesverband', true, 4, 'historic', null),
  ('19936', 'TBLSF', 'Trainer*in B Wettkampfklettern (alt)', 'Klettersport', 'license', 'B', 'Wettkampfklettern', 'Bundesverband', null, 4, 'historic', null),
  -- 3.2 Bergsport Sommer
  ('2303', 'WL', 'Wanderleiter*in', 'Bergsport Sommer', 'license', 'pre', 'Bergwandern', 'Bundesverband', false, 5, 'current', 'Fortbildungspflicht seit 2025, erste Prüfung bei Jahresmarke 2028; externe Fortbildungen zählen nicht'),
  ('2302', 'TCBW', 'Trainer*in C Bergwandern', 'Bergsport Sommer', 'license', 'C', 'Bergwandern', 'Bundesverband', true, 4, 'current', null),
  ('2301', 'TCBS', 'Trainer*in C Bergsteigen', 'Bergsport Sommer', 'license', 'C', 'Bergsteigen', 'Bundesverband', true, 4, 'current', null),
  ('19933', 'TCKS', 'Trainer*in C Klettersteig', 'Bergsport Sommer', 'license', 'C', 'Klettersteig', 'Bundesverband', true, 4, 'current', null),
  ('19934', 'TCAK', 'Trainer*in C Alpinklettern', 'Bergsport Sommer', 'license', 'C', 'Alpinklettern', 'Bundesverband', true, 4, 'current', null),
  ('2306', 'TCMG', 'Trainer*in C MTB Guide', 'Bergsport Sommer', 'license', 'C', 'Mountainbike Guide', 'Bundesverband', false, 4, 'current', 'DOSB nur über Bund Deutscher Radfahrer'),
  ('2307', 'TCMF', 'Trainer*in C MTB Fahrtechnik', 'Bergsport Sommer', 'license', 'C', 'Mountainbike Fahrtechnik', 'Bundesverband', false, 4, 'current', 'wie TCMG'),
  ('2308', 'TCMGF', 'Trainer*in C Mountainbike Guide & Fahrtechnik', 'Bergsport Sommer', 'license', 'C', 'Mountainbike Guide und Fahrtechnik', 'Bundesverband', false, 4, 'current', '[OFFEN] eigene Lizenz oder TCMG + TCMF?'),
  ('2297', 'TBHT', 'Trainer*in B Hochtouren', 'Bergsport Sommer', 'license', 'B', 'Hochtouren', 'Bundesverband', true, 4, 'current', null),
  ('2298', 'TBAK', 'Trainer*in B Alpinklettern', 'Bergsport Sommer', 'license', 'B', 'Alpinklettern', 'Bundesverband', true, 4, 'current', null),
  ('2299', 'TBPK', 'Trainer*in B Plaisirklettern', 'Bergsport Sommer', 'license', 'B', 'Plaisirklettern', 'Bundesverband', true, 4, 'current', 'Ausbildung 2027 nicht angeboten; Lizenz bleibt gültig'),
  ('2300', 'TBKS', 'Trainer*in B Klettersteig', 'Bergsport Sommer', 'license', 'B', 'Klettersteig', 'Bundesverband', true, 4, 'current', null),
  ('2305', 'TBMC', 'Trainer*in B MTB Coach', 'Bergsport Sommer', 'license', 'B', 'Mountainbike Coach', 'Bundesverband', false, 4, 'current', 'wie TCMG'),
  ('20636', 'UBPR', 'Übungsleiter*in B Bergwandern in der Prävention', 'Bergsport Sommer', 'license', 'B', 'Bergwandern Prävention', 'Bundesverband', true, 4, 'current', null),
  ('2312', 'TBS', 'Qualifizierungslehrgang Alpin', 'Bergsport Sommer', 'course', null, 'Alpin', 'Bundesverband', null, null, 'current', 'Zugang für Trainer*innen Klettersport zu alpinen C-/B-Stufen; keine Lizenz'),
  ('2310', 'ZQLB', 'Zusatzqualifikation Leistungsbergsteigen', 'Bergsport Sommer', 'add_on', null, 'Leistungsbergsteigen', 'Bundesverband', null, null, 'historic', 'nicht in Q5'),
  ('19941', 'MTB', 'Fachübungsleiter*in Mountainbike', 'Bergsport Sommer', 'license', 'C', 'Mountainbike Guide', 'Bundesverband', false, 4, 'historic', 'gleichgesetzt mit Trainer*in C Mountainbike Guide'),
  ('19942', 'PSA', 'Persönliche Schutzausrüstung', 'Bergsport Sommer', 'training', null, 'PSA-Prüfung', '[OFFEN]', null, null, 'historic', 'keine DAV-Lizenz; Prüfintervall und Aussteller klären'),
  -- 3.3 Berg- und Klettersport Winter
  ('19944', 'SK', 'Fachübungsleiter*in Skilauf', 'Berg- und Klettersport Winter', 'license', 'none', 'Skilauf', 'Bundesverband', false, 4, 'current', 'BLSV-Lizenz nur in Bayern'),
  ('2294', 'TCSB', 'Trainer*in C Skibergsteigen', 'Berg- und Klettersport Winter', 'license', 'C', 'Skibergsteigen', 'Bundesverband', true, 4, 'current', null),
  ('146324', 'TCSS', 'Trainer*in C Schneeschuhbergsteigen', 'Berg- und Klettersport Winter', 'license', 'C', 'Schneeschuhbergsteigen', 'Bundesverband', true, 4, 'current', 'seit 2025; DOSB laut Seite Bergsport Winter'),
  ('146321', 'TCEK', 'Trainer*in C Eisklettern', 'Berg- und Klettersport Winter', 'license', 'C', 'Eisklettern', 'Bundesverband', null, 4, 'current', null),
  ('2291', 'TBSH', 'Trainer*in B Skihochtour', 'Berg- und Klettersport Winter', 'license', 'B', 'Skihochtour', 'Bundesverband', true, 4, 'current', null),
  ('2292', 'TBEK', 'Trainer*in B Eisklettern', 'Berg- und Klettersport Winter', 'license', 'B', 'Eisklettern', 'Bundesverband', true, 4, 'current', 'Kürzel fehlt in Q1; in Q3 „Eisfallklettern“; nicht in Struktur 2027'),
  ('2290', 'FRG', 'DAV Freeride Guide', 'Berg- und Klettersport Winter', 'license', 'none', 'Freeride', 'Bundesverband', false, 4, 'current', null),
  ('2293', 'LL', 'Fachübungsleiter*in Skilanglauf', 'Berg- und Klettersport Winter', 'license', 'none', 'Skilanglauf', 'Bundesverband', false, 4, 'historic', 'nicht in Q5'),
  ('2296', 'ZQSS', 'Zusatzqualifikation Schneeschuhbergsteigen', 'Berg- und Klettersport Winter', 'add_on', null, 'Schneeschuhbergsteigen', 'Bundesverband', null, null, 'historic', '2025 abgelöst durch TCSS; Nachqualifizierung möglich'),
  ('19931', 'ZQEIS', 'Zusatzqualifikation Eisfallklettern (alt)', 'Berg- und Klettersport Winter', 'add_on', null, 'Eisfallklettern', 'Bundesverband', null, null, 'historic', null),
  ('19932', 'ZQFR', 'Zusatzqualifikation Freeride (alt)', 'Berg- und Klettersport Winter', 'add_on', null, 'Freeride', 'Bundesverband', null, null, 'historic', null),
  -- 3.4 Jugend und Familie
  ('2304', 'FGL', 'Familiengruppenleiter*in', 'Jugend und Familie', 'license', 'pre', 'Familienbergsteigen', 'Bundesverband', false, 3, 'current', 'Q5 kennt Varianten Wandern und Klettern [OFFEN]'),
  ('2326', 'JL', 'Jugendleiter*in', 'Jugend und Familie', 'license', 'none', 'Jugendarbeit', 'Bundesverband (JDAV)', null, 1, 'current', 'R7; Kürzel fehlt in Q1')
on conflict (source_ref) where source_ref is not null do nothing;
