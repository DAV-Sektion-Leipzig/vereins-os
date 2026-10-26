// FT24 (R38, R40, R42, R43; C11): Lastschriftdatei pain.008.001.02 – Aufbau wie die Vorlage der Sparkasse, Summen je
// Zahlungsgruppe und gesamt, Sequenzen, Mandat, Gläubiger-ID. Mit PAIN008_XSD=<Pfad zu pain.008.001.02.xsd> zusätzlich
// Prüfung gegen das Schema (xmllint). Nur fiktive Daten; IBAN nur die Beispiel-IBAN, Gläubiger-ID nur die Test-Kennung.
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'
import { buildPain008, debitProblems, type CollectionExport } from '../../src/features/fi/export/sepaDebit.ts'

const IBAN = 'DE89370400440532013000'

function line(n: number, sequence: 'FRST' | 'RCUR', amount: number, extra?: number): CollectionExport['lines'][number] {
  return {
    sort_no: n,
    participant_first_name: 'Kind',
    participant_last_name: `Test${n}`,
    participant_preferred_name: null,
    holder_name: `Elternteil ${n}`,
    group_label: 'Jugendgruppe Test 1',
    mandate_reference: `TEST-GR-${n}`,
    mandate_signed_on: '2026-09-15',
    sequence,
    monthly_amount: amount - (extra ?? 0),
    extra_amount: extra ?? null,
    extra_text: extra ? 'und rückwirkend bis Oktober 2026' : null,
    amount,
    remittance: `Jugendgruppe Test 1 Beitragszahlung Dezember 2026${extra ? ' und rückwirkend bis Oktober 2026' : ''}`,
    end_to_end_id: `FI-L-2026-12-01-${String(n).padStart(4, '0')}`,
    account_holder: n === 2 ? 'Anna & Ben Müller' : `Elternteil ${n}`,
    iban: IBAN,
    bank_changed: false,
  }
}

function sample(): CollectionExport {
  return {
    run: {
      id: 'r', month: '2026-12-01', number: 1, due_date: '2026-12-07', msg_id: 'FI-L-2026-12-01-AB12CD34',
      pmt_inf_id_frst: 'FI-L-2026-12-01-AB12CD34-FRST', pmt_inf_id_rcur: 'FI-L-2026-12-01-AB12CD34-RCUR',
      line_count: 3, total: 87, released_at: '2026-12-02T09:59:30.846+00:00', released_by_name: 'Gerd Geschäftsstelle',
    },
    creditor: {
      debtor_name: 'Sektion Test', iban: 'DE89 3704 0044 0532 0130 00', bic: 'TESTDEFFXXX', ledger_account: '0000 0',
      valid_from: '2026-01-01', creditor_id: 'DE98ZZZ09999999999', ledger_account_collection: '0000 1',
    },
    lines: [line(1, 'RCUR', 21), line(2, 'RCUR', 46, 25), line(3, 'FRST', 20)],
  }
}

const tag = (xml: string, name: string) => [...xml.matchAll(new RegExp(`<${name}[^>]*>([^<]*)</${name}>`, 'g'))].map((m) => m[1])

test('Kopf und Zahlungsgruppen: Summe und Anzahl gesamt und je Sequenz', () => {
  const xml = buildPain008(sample())
  assert.match(xml, /<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.001.02"/)
  assert.deepEqual(tag(xml, 'NbOfTxs'), ['3', '1', '2'])
  assert.deepEqual(tag(xml, 'CtrlSum'), ['87.00', '20.00', '67.00'])
  assert.deepEqual(tag(xml, 'SeqTp'), ['FRST', 'RCUR'])
  assert.deepEqual(tag(xml, 'PmtInfId'), ['FI-L-2026-12-01-AB12CD34-FRST', 'FI-L-2026-12-01-AB12CD34-RCUR'])
  assert.deepEqual(tag(xml, 'PmtMtd'), ['DD', 'DD'])
  assert.deepEqual(tag(xml, 'Cd'), ['SEPA', 'CORE', 'SEPA', 'CORE'])
  assert.deepEqual(tag(xml, 'ReqdColltnDt'), ['2026-12-07', '2026-12-07'])
  assert.deepEqual(tag(xml, 'CreDtTm'), ['2026-12-02T10:59:30+01:00'])
})

test('Gläubiger, Mandat, Zahlungspflichtige wie die Vorlage', () => {
  const xml = buildPain008(sample())
  assert.equal(tag(xml, 'Prtry')[0], 'SEPA')
  assert.ok(xml.includes('<Id>DE98ZZZ09999999999</Id>'))
  assert.deepEqual(tag(xml, 'MndtId'), ['TEST-GR-3', 'TEST-GR-1', 'TEST-GR-2'])
  assert.deepEqual(tag(xml, 'DtOfSgntr'), ['2026-09-15', '2026-09-15', '2026-09-15'])
  assert.equal(tag(xml, 'Id').filter((v) => v === 'NOTPROVIDED').length, 3)
  assert.deepEqual(tag(xml, 'InstdAmt'), ['20.00', '21.00', '46.00'])
  assert.ok(xml.includes('<Nm>Anna &amp; Ben Müller</Nm>'))
  assert.ok(xml.includes('<Ustrd>Jugendgruppe Test 1 Beitragszahlung Dezember 2026 und rückwirkend bis Oktober 2026</Ustrd>'))
  assert.ok(!xml.includes('BtchBookg') && !xml.includes('ChrgBr'))
})

test('nur Folgelastschriften: eine Zahlungsgruppe', () => {
  const data = sample()
  data.lines = data.lines.filter((l) => l.sequence === 'RCUR')
  const xml = buildPain008(data)
  assert.deepEqual(tag(xml, 'SeqTp'), ['RCUR'])
  assert.deepEqual(tag(xml, 'NbOfTxs'), ['2', '2'])
})

test('fehlende Gläubiger-ID oder Bankverbindung werden gemeldet', () => {
  const data = sample()
  data.creditor!.creditor_id = null
  data.lines[0].iban = null
  assert.deepEqual(debitProblems(data), [
    'Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren.',
    'Bankverbindung fehlt: Kind Test1',
  ])
})

test('Schema pain.008.001.02 (nur mit PAIN008_XSD)', { skip: !process.env.PAIN008_XSD }, () => {
  const dir = mkdtempSync(join(tmpdir(), 'pain008-'))
  const file = join(dir, 'test.xml')
  writeFileSync(file, buildPain008(sample()))
  execFileSync('xmllint', ['--noout', '--schema', process.env.PAIN008_XSD as string, file], { stdio: 'pipe' })
})
