// FT14 (R26, R28): Überweisungsdatei pain.001.001.03 – Aufbau, Summe = CtrlSum, Zeilen = NbOfTxs, Zeichensatz.
// Mit PAIN001_XSD=<Pfad zu pain.001.001.03.xsd> zusätzlich Prüfung gegen das Schema (xmllint).
// Nur fiktive Daten; IBAN nur die bekannte Beispiel-IBAN.
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'
import { buildPain001, isoDateTimeBerlin, sepaProblems, sepaText, toCents, type PayoutExport } from '../../src/features/fi/export/sepa.ts'

const IBAN = 'DE89370400440532013000'

function sample(): PayoutExport {
  return {
    run: {
      id: '00000000-0000-0000-0000-000000000001',
      year: 2026,
      half: 1,
      number: 1,
      execution_date: '2026-07-31',
      msg_id: 'FI-2026-1-01-AB12CD34',
      pmt_inf_id: 'FI-2026-1-01-AB12CD34-P',
      line_count: 3,
      total: 456.6,
      released_at: '2026-07-30T08:15:30.123456+00:00',
      released_by_name: 'Gerd Geschäftsstelle',
    },
    debtor: { debtor_name: 'Sektion Test', iban: 'DE89 3704 0044 0532 0130 00', bic: 'TESTDEFFXXX', ledger_account: '0000 0', valid_from: '2026-01-01' },
    confirmations: [],
    lines: [
      { sort_no: 2, last_name: 'Beispiel', first_name: 'Ben', amount: 100.1, group_label: 'Gruppe 2', remittance: 'ÜL-Vergütung 1. Hj 2026 Gruppe 2', end_to_end_id: 'FI-2026-1-01-0002', account_holder: 'Ben Beispiel', iban: IBAN, bank_changed: false },
      { sort_no: 1, last_name: 'Müller-Lüdenscheidt', first_name: 'Zoë', amount: 200.2, group_label: 'Gruppe 1', remittance: 'ÜL-Vergütung 1. Hj 2026 Gruppe 1', end_to_end_id: 'FI-2026-1-01-0001', account_holder: 'Zoë Müller-Lüdenscheidt <Test> & Co', iban: IBAN, bank_changed: false },
      { sort_no: 3, last_name: 'Test', first_name: 'Tina', amount: 156.3, group_label: 'Leistungsgruppe Test', remittance: 'ÜL-Vergütung 1. Hj 2026 Leistungsgruppe Test', end_to_end_id: 'FI-2026-1-01-0003', account_holder: 'Tina Test', iban: IBAN, bank_changed: false },
    ],
  }
}

const tag = (xml: string, name: string) => [...xml.matchAll(new RegExp(`<${name}[^>]*>([^<]*)</${name}>`, 'g'))].map((m) => m[1])

test('Summe der Zeilen = CtrlSum, Anzahl = NbOfTxs (Kopf und Zahlungsgruppe)', () => {
  const data = sample()
  const xml = buildPain001(data)
  const cents = data.lines.reduce((s, l) => s + toCents(l.amount), 0)
  assert.deepEqual(tag(xml, 'CtrlSum'), ['456.60', '456.60'])
  assert.equal(cents, toCents(data.run.total))
  assert.deepEqual(tag(xml, 'NbOfTxs'), ['3', '3'])
  assert.deepEqual(tag(xml, 'InstdAmt'), ['200.20', '100.10', '156.30'])
  assert.deepEqual(tag(xml, 'EndToEndId'), ['FI-2026-1-01-0001', 'FI-2026-1-01-0002', 'FI-2026-1-01-0003'])
})

test('Kopf, Sektion und Ausführungsdatum nach C7', () => {
  const xml = buildPain001(sample())
  assert.match(xml, /^<\?xml version="1.0" encoding="UTF-8"\?>\n<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.03"/)
  assert.deepEqual(tag(xml, 'MsgId'), ['FI-2026-1-01-AB12CD34'])
  assert.deepEqual(tag(xml, 'PmtInfId'), ['FI-2026-1-01-AB12CD34-P'])
  assert.deepEqual(tag(xml, 'PmtMtd'), ['TRF'])
  assert.deepEqual(tag(xml, 'Cd'), ['SEPA'])
  assert.deepEqual(tag(xml, 'ReqdExctnDt'), ['2026-07-31'])
  assert.deepEqual(tag(xml, 'CreDtTm'), ['2026-07-30T10:15:30+02:00'])
  assert.deepEqual(tag(xml, 'IBAN'), [IBAN, IBAN, IBAN, IBAN])
  assert.deepEqual(tag(xml, 'BIC'), ['TESTDEFFXXX'])
  assert.ok(!xml.includes('BtchBookg'))
})

test('Zeichensatz: Umlaute bleiben, Akzente und Sonderzeichen ersetzt, XML maskiert, Längen begrenzt', () => {
  const xml = buildPain001(sample())
  assert.ok(xml.includes('<Nm>Zoe Müller-Lüdenscheidt Test &amp; Co</Nm>'))
  assert.ok(xml.includes('<Ustrd>ÜL-Vergütung 1. Hj 2026 Gruppe 1</Ustrd>'))
  assert.equal(sepaText('x'.repeat(200), 140).length, 140)
  assert.equal(sepaText('Ångström @ Straße_1', 70), 'Angström Straße 1')
})

test('Zeitzone im Winter +01:00', () => {
  assert.equal(isoDateTimeBerlin('2026-12-01T09:00:00Z'), '2026-12-01T10:00:00+01:00')
})

test('Fehlende Bankverbindung oder Angaben der Sektion werden gemeldet', () => {
  const data = sample()
  data.lines[0].iban = null
  data.debtor = null
  assert.deepEqual(sepaProblems(data), [
    'Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.',
    'Bankverbindung fehlt: Ben Beispiel',
  ])
})

test('Schema pain.001.001.03 (nur mit PAIN001_XSD)', { skip: !process.env.PAIN001_XSD }, () => {
  const dir = mkdtempSync(join(tmpdir(), 'pain001-'))
  const file = join(dir, 'test.xml')
  writeFileSync(file, buildPain001(sample()))
  execFileSync('xmllint', ['--noout', '--schema', process.env.PAIN001_XSD as string, file], { stdio: 'pipe' })
})
