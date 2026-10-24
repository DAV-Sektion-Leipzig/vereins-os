import assert from 'node:assert/strict'
import { test } from 'node:test'
import { buildReport } from './report.ts'

test('Bericht mit Kopf, Fehlern, Warnungen und Zusammenfassung; ohne Schlüssel', () => {
  const md = buildReport({
    file: 'aktive.csv',
    projectRef: 'abcdefghijklmnopqrst',
    cutoff: '2026-10-01',
    at: new Date('2026-10-01T10:00:00Z'),
    mode: 'dry-run',
    formatErrors: [{ row: 3, message: 'Zeile 3: aktiv nicht lesbar' }],
    result: {
      errors: [{ row: 2, message: 'Zeile 2: Qualifikationsart XYZ unbekannt' }],
      warnings: [{ row: 6, message: 'Zeile 6: Dublettenverdacht zu Toni Muster (vorhanden)' }],
      counts: { persons: 5, license: 3, function: 6, valid_from_cutoff: 11 },
      written: false,
    },
  })
  assert.match(md, /^# Prüfbericht Migration der Aktivenliste/)
  assert.match(md, /- Stichtag: 01\.10\.2026/)
  assert.match(md, /## Fehler \(2\)\n\n- Zeile 2: Qualifikationsart XYZ unbekannt\n- Zeile 3: aktiv nicht lesbar/)
  assert.match(md, /## Warnungen \(1\)\n\n- Zeile 6: Dublettenverdacht zu Toni Muster/)
  assert.match(md, /- Personen: 5\n- function: 6\n- license: 3\n- Eigenschaften mit „gültig von“ = Stichtag: 11/)
  assert.doesNotMatch(md, /sb_secret|service_role|Secret/i)
})
