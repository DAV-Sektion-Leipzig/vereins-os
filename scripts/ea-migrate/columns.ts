// Spalten der Migrationsvorlage (01-erhebung.md C3, contracts/migration-script.md; T022).

const LICENSE_COLUMNS = [1, 2, 3].flatMap((n) =>
  ['art', 'nummer', 'gueltig_bis', 'dosb_gueltig_bis', 'letzte_fb', 'erworben_am'].map((s) => `l${n}_${s}`),
)

/** Spalten, die die Kopfzeile enthalten muss; fehlt eine, bricht das Skript ab („Spalte <name> fehlt.“). */
export const REQUIRED_COLUMNS = [
  'nachname', 'vorname', 'rufname', 'aktiv', 'aktiv_seit', 'referate', 'te_pro_woche', 'mitgliedsnummer',
  'geburtsdatum', 'geschlecht', 'email', 'telefon_mobil', 'telefon_festnetz', 'strasse', 'plz', 'ort', 'dav_email',
  'kontoinhaber', 'iban', ...LICENSE_COLUMNS, 'qualifikationen', 'ausweis_nr', 'ausweis_kopie', 'fz_ausgestellt',
  'fz_eingesehen', 'ehrenkodex', 'trainervereinbarung', 'ehrenamtspass_ausgegeben', 'ehrenamtspass_gueltig_bis',
  'schluessel_nolimit', 'schluessel_k4', 'k4_karte', 'vereinsjacke', 'dav360', 'forms', 'jdav_verteiler', 'redaktion',
  'mailingliste', 'jugendausschuss', 'auszeichnung_art', 'auszeichnung_datum', 'gruppe', 'gruppenleitung',
]

/** Optionale Spalten mit Datum zu einer anderen Spalte (C3: „optional <spalte>_am“, „jugendausschuss_seit“). */
export const OPTIONAL_COLUMNS = ['schluessel_nolimit_am', 'schluessel_k4_am', 'k4_karte_am', 'vereinsjacke_am', 'jugendausschuss_seit']

/** Jahresspalten: fb_<jahr>, fb_vor_2016, marke_<jahr>, foerderung_<jahr>, jahreskarte_<jahr>. */
export const YEAR_COLUMN = /^(fb|marke|foerderung|jahreskarte)_(\d{4}|vor_2016)$/

/** Spalten mit Datum TT.MM.JJJJ (ohne Jahresspalten). */
export const DATE_COLUMNS = new Set([
  'aktiv_seit', 'geburtsdatum', 'fz_ausgestellt', 'fz_eingesehen', 'ehrenkodex', 'trainervereinbarung',
  'ehrenamtspass_ausgegeben', 'ehrenamtspass_gueltig_bis', 'auszeichnung_datum', 'jugendausschuss_seit',
  'schluessel_nolimit_am', 'schluessel_k4_am', 'k4_karte_am', 'vereinsjacke_am',
  ...[1, 2, 3].flatMap((n) => ['gueltig_bis', 'dosb_gueltig_bis', 'letzte_fb', 'erworben_am'].map((s) => `l${n}_${s}`)),
])

/** Spalten mit ja/nein. */
export const BOOLEAN_COLUMNS = new Set(['aktiv', 'ausweis_kopie', 'jugendausschuss'])

/** Zugänge extern: „x“ oder Datum seit. */
export const ACCESS_COLUMNS = new Set(['dav360', 'forms', 'jdav_verteiler', 'redaktion', 'mailingliste'])

/** Kopfzeile der Vorlage (vorlage.csv): Pflicht- und optionale Spalten, Fortbildungen vor 2016 bis 2026. */
export const TEMPLATE_HEADER = [
  ...REQUIRED_COLUMNS,
  ...OPTIONAL_COLUMNS,
  'fb_vor_2016',
  ...Array.from({ length: 11 }, (_, i) => `fb_${2016 + i}`),
]
