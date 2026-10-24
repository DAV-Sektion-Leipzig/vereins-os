import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import { TEMPLATE_HEADER } from './columns.ts'
import { MissingColumnError, parseCsv, toBoolean, toIsoDate } from './csv.ts'

const header = TEMPLATE_HEADER.join(';')
const line = (values: Record<string, string>) => TEMPLATE_HEADER.map((c) => values[c] ?? '').join(';')

test('Kopfzeile ohne Pflichtspalte → „Spalte <name> fehlt.“', () => {
  const content = TEMPLATE_HEADER.filter((c) => c !== 'aktiv').join(';') + '\n'
  assert.throws(() => parseCsv(content), (e: unknown) => e instanceof MissingColumnError && e.message === 'Spalte aktiv fehlt.')
})

test('Datumsumwandlung TT.MM.JJJJ → ISO, ungültige Daten null', () => {
  assert.equal(toIsoDate('15.05.2026'), '2026-05-15')
  assert.equal(toIsoDate('1.3.2025'), '2025-03-01')
  assert.equal(toIsoDate('31.02.2026'), null)
  assert.equal(toIsoDate('2026-05-15'), null)
})

test('ja/nein → boolean', () => {
  assert.equal(toBoolean('Ja'), true)
  assert.equal(toBoolean('nein'), false)
  assert.equal(toBoolean('vielleicht'), null)
})

test('Zeile in die Form der Datenbank: Zeilennummer, Listen, Datum, Zahl, leere Zellen fehlen', () => {
  const { rows, formatErrors } = parseCsv(
    [header, line({ nachname: 'Kletter', vorname: 'Clara', aktiv: 'ja', referate: 'Klettern, Ausbildung', te_pro_woche: '2,5',
      l1_art: 'TCSPI', l1_gueltig_bis: '31.12.2027', qualifikationen: 'EH:01.02.2025:01.02.2027, ZQOS::: Fels:Sachsen',
      dav360: '01.03.2024', forms: 'x' })].join('\n'),
  )
  assert.deepEqual(formatErrors, [])
  assert.deepEqual(rows, [{
    row: 2, nachname: 'Kletter', vorname: 'Clara', aktiv: true, referate: ['Klettern', 'Ausbildung'], te_pro_woche: 2.5,
    l1_art: 'TCSPI', l1_gueltig_bis: '2027-12-31',
    qualifikationen: [{ code: 'EH', date: '2025-02-01', valid_until: '2027-02-01' }, { code: 'ZQOS', detail: 'Fels:Sachsen' }],
    dav360: '2024-03-01', forms: 'x',
  }])
})

test('Jahresspalten: fb, fb_vor_2016 als 2015 mit Zusatz, Marke, Förderung, Jahreskarte', () => {
  const content = `${header};marke_2024;foerderung_2025;jahreskarte_2026\n` +
    `${line({ nachname: 'A', vorname: 'B', aktiv: 'nein', fb_vor_2016: 'Grundkurs', fb_2023: 'Update' })};01.03.2024;ja;15.01.2026\n`
  const { rows, formatErrors } = parseCsv(content)
  assert.deepEqual(formatErrors, [])
  assert.deepEqual(rows[0].fb, { '2015': 'Grundkurs (vor 2016)', '2023': 'Update' })
  assert.deepEqual(rows[0].marke, { '2024': '2024-03-01' })
  assert.deepEqual(rows[0].foerderung, { '2025': true })
  assert.deepEqual(rows[0].jahreskarte, { '2026': '2026-01-15' })
})

test('Formatfehler mit Zeilennummer; die Zeile wird ohne den fehlerhaften Wert übergeben', () => {
  const { rows, formatErrors } = parseCsv([header,
    line({ nachname: 'A', vorname: 'B', aktiv: 'ja' }),
    line({ nachname: 'C', vorname: 'D', aktiv: 'vielleicht', geburtsdatum: '32.01.1990', dav360: 'irgendwann' })].join('\n'))
  assert.deepEqual(formatErrors, [
    { row: 3, message: 'Zeile 3: aktiv nicht lesbar' },
    { row: 3, message: 'Zeile 3: geburtsdatum nicht lesbar' },
    { row: 3, message: 'Zeile 3: dav360 nicht lesbar' },
  ])
  assert.deepEqual(rows[1], { row: 3, nachname: 'C', vorname: 'D' })
})

test('Beispieldateien und Vorlage lesbar', () => {
  for (const [name, count] of [['vorlage.csv', 0], ['beispiel.csv', 5], ['beispiel-fehler.csv', 2]] as const) {
    const { rows, formatErrors } = parseCsv(readFileSync(new URL(name, import.meta.url), 'utf8'))
    assert.equal(rows.length, count, name)
    assert.deepEqual(formatErrors, [], name)
  }
})
