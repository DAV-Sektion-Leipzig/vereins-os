// DT14 (spec.md DS v0.2 Abschnitt 1, plan.md P6): Lesen von DATEV-Kontenblättern, Finanzplan-Blatt und zuordnung.csv
// im Browser. Nur fiktive Daten (Beträge, Texte, Kontonamen).
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { decodeText, parseAmount, parseCsv, parseGermanDate } from '../../src/features/ds/budget/parse/csv.ts'
import { parseDatev, parseDatevText } from '../../src/features/ds/budget/parse/datev.ts'
import { findPlanSheet, parsePlanSheet } from '../../src/features/ds/budget/parse/plan.ts'
import { parseZuordnungText } from '../../src/features/ds/budget/parse/zuordnung.ts'

const DATEV = [
  'Mandant;Beispielverein;Berater;1;Exportzeit;18.10.2026 10:00',
  '',
  'Kontenübersicht',
  'Konto;Beschriftung;EB-Wert;Umsatz Soll;Umsatz Haben',
  '6326 3;Übungsleiter;0,00;1.300,00;20,00',
  '4000 0;Beiträge;;;1.000,00',
  '',
  'Buchungsliste',
  'Konto;Beschriftung Konto;Datum;BU;Gegenkonto;Beschriftung Gegenkonto;Buchungstext;Belegfeld 1;Umsatz Soll;Umsatz Haben;KOST1',
  '6326 3;Übungsleiter;10.02.2026;;1200;Bank;"Übungsleiter; Februar";A1;1.300,00;;1',
  '6326 3;Übungsleiter;01.04.2026;;1200;Bank;Storno;A2;;20,00;1',
  '6326 3;Übungsleiter;01.01.2026;;9000;Saldenvorträge;EB-Wert;;5.000,00;;',
  '4000 0;Beiträge;31.02.2026;;1200;Bank;Datum falsch;E1;;1.000,00;',
].join('\r\n')

test('CSV: Anführungszeichen, Trennzeichen im Feld, CRLF', () => {
  assert.deepEqual(parseCsv('a;"b;c";"d ""e"""\r\n1;2;3'), [['a', 'b;c', 'd "e"'], ['1', '2', '3']])
})

test('Beträge und Datum im deutschen Format', () => {
  assert.equal(parseAmount('1.234,56'), 1234.56)
  assert.equal(parseAmount('-20,5'), -20.5)
  assert.equal(parseAmount(''), null)
  assert.ok(Number.isNaN(parseAmount('abc') as number))
  assert.equal(parseAmount(17), 17)
  assert.equal(parseGermanDate('10.02.2026'), '2026-02-10')
  assert.equal(parseGermanDate('1.2.26'), '2026-02-01')
  assert.equal(parseGermanDate('31.02.2026'), null)
})

test('Zeichensatz: UTF-8 mit BOM und Windows-1252', () => {
  const utf8 = new Uint8Array([0xef, 0xbb, 0xbf, ...new TextEncoder().encode('Übung')])
  assert.equal(decodeText(utf8), 'Übung')
  assert.equal(decodeText(new Uint8Array([0xdc, 0x62, 0x75, 0x6e, 0x67])), 'Übung')
})

test('DATEV: Kontenübersicht, Buchungsliste, Spalten über Namen', () => {
  const result = parseDatev('Kontenblatt.csv', new TextEncoder().encode(DATEV))
  assert.ok(result.ok)
  if (!result.ok) return
  assert.equal(result.file.info, 'Mandant · Beispielverein · Berater · 1 · Exportzeit · 18.10.2026 10:00')
  assert.deepEqual(result.file.overview[0], { konto: '6326 3', eb: 0, soll: 1300, haben: 20 })
  assert.equal(result.file.overview[1].soll, null)
  assert.equal(result.file.rows.length, 4)
  assert.deepEqual(result.file.rows[0], {
    line: 10, konto: '6326 3', datum: '2026-02-10', bu: '', gegenkonto: '1200', gegenkonto_label: 'Bank',
    text: 'Übungsleiter; Februar', beleg: 'A1', soll: 1300, haben: null, kost1: '1',
  })
  assert.equal(result.file.rows[2].text, 'EB-Wert')
  assert.deepEqual(result.problems, [{ line: 13, type: 'date', value: '31.02.2026' }])
})

test('DATEV: andere Spaltenreihenfolge', () => {
  const text = 'Buchungstext;Umsatz Haben;Umsatz Soll;Datum;Konto\r\nTest;;12,00;03.03.2026;6330 5'
  const result = parseDatevText('x.csv', text)
  assert.ok(result.ok)
  if (result.ok) assert.deepEqual([result.file.rows[0].konto, result.file.rows[0].soll], ['6330 5', 12])
})

test('DATEV: ohne Buchungsliste oder mit fehlender Spalte', () => {
  assert.deepEqual(parseDatevText('x.csv', 'Konto;EB-Wert\r\n6326 3;0'), { ok: false, error: 'no_bookings' })
  const missing = parseDatevText('x.csv', 'Konto;Buchungstext;Umsatz Soll\r\n6326 3;a;1')
  assert.equal(missing.ok, false)
  if (!missing.ok) assert.deepEqual(missing.missing, ['datum', 'haben'])
})

test('Finanzplan: Blatt finden, Einnahmen und Ausgaben nebeneinander, Summenzeilen', () => {
  assert.equal(findPlanSheet([{ sheet: 'Übersicht' }, { sheet: 'finanzplan  2026' }], 2026)?.sheet, 'finanzplan  2026')
  assert.equal(findPlanSheet([{ sheet: 'Finanzplan 2025' }], 2026), undefined)
  const data = [
    ['Finanzplan 2026'],
    ['Einnahmen', 'Ist 2025', 'Plan 2026', null, 'Ausgaben', 'Ist 2025', 'Plan 2026'],
    ['Mitgliedsbeiträge', 4800, 5000, null, 'Material Klettern', 90, 100],
    [null, null, null, null, 'Vergütung Aktive', 900, '1.000,00'],
    [null, null, null, null, 'Sonstiges', 0, 0],
    [null, null, null, null, 'Leer', null, null],
    ['Summe Einnahmen', 4800, 5000, null, 'Summe Ausgaben', 990, 1100],
  ]
  const result = parsePlanSheet('Finanzen.xlsx', 'Finanzplan 2026', data, 2026)
  assert.ok(result.ok)
  if (!result.ok) return
  assert.deepEqual(result.source.items, [
    { kind: 'income', name: 'Mitgliedsbeiträge', plan: 5000, row: 3 },
    { kind: 'expense', name: 'Material Klettern', plan: 100, row: 3 },
    { kind: 'expense', name: 'Vergütung Aktive', plan: 1000, row: 4 },
    { kind: 'expense', name: 'Sonstiges', plan: 0, row: 5 },
  ])
  assert.deepEqual(result.source.sums, { income: 5000, expense: 1100 })
})

test('Finanzplan: Fehler', () => {
  assert.deepEqual(parsePlanSheet('f', 's', [['A', 'B']], 2026), { ok: false, error: 'header_missing' })
  assert.deepEqual(parsePlanSheet('f', 's', [['Einnahmen', 'Plan 2025', 'Ausgaben', 'Plan 2025']], 2026),
    { ok: false, error: 'plan_column_missing' })
  assert.deepEqual(parsePlanSheet('f', 's', [['Einnahmen', 'Plan 2026', 'Ausgaben', 'Plan 2026'], ['X', 'abc', null, null]], 2026),
    { ok: false, error: 'amount', row: 2 })
})

test('zuordnung.csv: Spalten über Namen, leere Zeilen übersprungen', () => {
  const result = parseZuordnungText(
    'Konto;Kontobezeichnung;Art;Gesamtbudget;Budgetposten;Kostenstelle;Status;Hinweis;Datum;Beleg;Betrag;Buchungstext\r\n' +
    '6326 3;Übungsleiter;Ausgabe;Klettern;Vergütung Aktive;;ok;;;;;\r\n;;;;;;;;;;;\r\n' +
    '6330 5;Material;Ausgabe;Klettern;Material Klettern;;;;10.02.2026;A1;"1.300,00 S";Seile\r\n')
  assert.ok(result.ok)
  if (!result.ok) return
  assert.equal(result.rows.length, 2)
  assert.equal(result.rows[1].line, 4)
  assert.equal(result.rows[1].betrag, '1.300,00 S')
})
