import assert from 'node:assert/strict'
import { test } from 'node:test'
import type { ImportResult } from './report.ts'
import {
  ALREADY_RUN,
  ALREADY_RUN_MESSAGE,
  EXIT,
  main,
  parseArgs,
  projectRef,
  RpcError,
  UNKNOWN_RESULT_MESSAGE,
  type Io,
  type Rpc,
} from './run.ts'
import { TEMPLATE_HEADER } from './columns.ts'

const URL_TEST = 'https://abcdefghijklmnopqrst.supabase.co'
const KEY = 'sb_secret_nur-im-test'
const csv = `${TEMPLATE_HEADER.join(';')}\n${TEMPLATE_HEADER.map((c) => ({ nachname: 'A', vorname: 'B', aktiv: 'ja' })[c] ?? '').join(';')}\n`
const clean: ImportResult = { errors: [], warnings: [], counts: { persons: 1 }, written: false }

function fakeIo(answers: string[], hidden: string, rpc: Rpc) {
  const files: Record<string, string> = {}
  const logs: string[] = []
  const calls: boolean[] = []
  const io: Io = {
    readFile: async () => csv,
    writeFile: async (path, content) => {
      files[path] = content
    },
    ask: async () => answers.shift() ?? '',
    askHidden: async () => hidden,
    log: (m) => logs.push(m),
    connect: (url, key) => {
      assert.equal(url, URL_TEST)
      assert.equal(key, KEY)
      return async (rows, cutoff, dryRun) => {
        calls.push(dryRun)
        return rpc(rows, cutoff, dryRun)
      }
    },
    now: () => new Date('2026-10-01T10:00:00Z'),
  }
  return { io, files, logs, calls }
}

test('Argumente: genau eines von --dry-run und --run, Stichtag TT.MM.JJJJ', () => {
  const today = new Date('2026-10-01T10:00:00Z')
  assert.deepEqual(parseArgs(['--file', 'a.csv', '--dry-run'], today), { file: 'a.csv', mode: 'dry-run', cutoff: '2026-10-01' })
  assert.deepEqual(parseArgs(['--file', 'a.csv', '--run', '--cutoff', '1.10.2026'], today), { file: 'a.csv', mode: 'run', cutoff: '2026-10-01' })
  assert.equal(typeof parseArgs(['--file', 'a.csv'], today), 'string')
  assert.equal(typeof parseArgs(['--file', 'a.csv', '--dry-run', '--run'], today), 'string')
})

test('Project Ref aus der Projekt-URL', () => {
  assert.equal(projectRef(URL_TEST), 'abcdefghijklmnopqrst')
  assert.equal(projectRef('http://localhost:54321'), null)
})

test('leerer Schlüssel → „Schlüssel fehlt.“', async () => {
  const { io, logs, calls } = fakeIo([URL_TEST], '', async () => clean)
  assert.equal(await main(['--file', 'a.csv', '--dry-run'], io), EXIT.usage)
  assert.deepEqual(logs, ['Schlüssel fehlt.'])
  assert.deepEqual(calls, [])
})

test('Probelauf schreibt den Prüfbericht ohne Schlüssel', async () => {
  const { io, files, calls } = fakeIo([URL_TEST], KEY, async () => clean)
  assert.equal(await main(['--file', 'daten/a.csv', '--dry-run'], io), EXIT.ok)
  assert.deepEqual(calls, [true])
  assert.ok(files['daten/a.pruefbericht.md'])
  assert.ok(!files['daten/a.pruefbericht.md'].includes(KEY))
})

test('Lauf: falsche Projekt-Ref bricht ab, ohne die Datenbank aufzurufen', async () => {
  const { io, logs, calls } = fakeIo([URL_TEST, 'falsch'], KEY, async () => clean)
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
  assert.deepEqual(calls, [])
  assert.match(logs.at(-1)!, /Lauf abgebrochen/)
})

test('Lauf: Probelauf mit Fehlern → „Probelauf hat Fehler. Lauf abgebrochen.“', async () => {
  const withError: ImportResult = { ...clean, errors: [{ row: 2, message: 'Zeile 2: Referat X unbekannt' }] }
  const { io, logs, calls } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async () => withError)
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
  assert.deepEqual(calls, [true])
  assert.match(logs.at(-1)!, /^Probelauf hat Fehler\. Lauf abgebrochen\./)
})

test('Lauf: interner Probelauf, dann Schreiben und Abschlussbericht', async () => {
  const { io, files, calls } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async (_rows, _cutoff, dryRun) => ({ ...clean, written: !dryRun }))
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.ok)
  assert.deepEqual(calls, [true, false])
  assert.match(files['a.abschlussbericht.md'], /^# Abschlussbericht/)
})

test('Probelauf nach erfolgtem Import: Hinweis auf Wiederholungsschutz, Lauf abgebrochen (B-07)', async () => {
  const alreadyRun: ImportResult = {
    ...clean,
    errors: [
      {
        row: 0,
        code: ALREADY_RUN,
        message:
          'Der Import wurde bereits ausgeführt (5 Personen aus dem Migrationsskript vorhanden). Ein zweiter Lauf würde alle Personen doppelt anlegen.',
      },
    ],
  }
  const { io, logs, calls, files } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async () => alreadyRun)
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
  assert.deepEqual(calls, [true])
  assert.ok(logs.includes(ALREADY_RUN_MESSAGE))
  assert.match(logs.at(-1)!, /^Probelauf hat Fehler\. Lauf abgebrochen\./)
  assert.match(files['a.pruefbericht.md'], /Der Import wurde bereits ausgeführt/)
})

test('Lauf: EA_IMPORT_ALREADY_RUN der Datenbank → verständliche Meldung (B-07)', async () => {
  const { io, logs, calls } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async (_rows, _cutoff, dryRun) => {
    if (dryRun) return clean
    throw new RpcError(ALREADY_RUN, 'P0001')
  })
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
  assert.deepEqual(calls, [true, false])
  assert.equal(logs.at(-1), `${ALREADY_RUN_MESSAGE} Lauf abgebrochen, nichts geschrieben.`)
})

test('Lauf: Fehlerantwort der Datenbank → nichts geschrieben', async () => {
  const { io, logs } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async (_rows, _cutoff, dryRun) => {
    if (dryRun) return clean
    throw new RpcError('canceling statement due to statement timeout', '57014')
  })
  assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
  assert.equal(logs.at(-1), 'Aufruf fehlgeschlagen, nichts geschrieben: canceling statement due to statement timeout')
})

test('Lauf: keine Antwort (Netzwerk-Timeout) → Ergebnis unbekannt statt „nichts geschrieben“ (B-07)', async () => {
  for (const error of [new RpcError('TypeError: fetch failed'), new Error('socket hang up')]) {
    const { io, logs } = fakeIo([URL_TEST, 'abcdefghijklmnopqrst'], KEY, async (_rows, _cutoff, dryRun) => {
      if (dryRun) return clean
      throw error
    })
    assert.equal(await main(['--file', 'a.csv', '--run'], io), EXIT.findings)
    assert.ok(logs.at(-1)!.endsWith(UNKNOWN_RESULT_MESSAGE))
    assert.doesNotMatch(logs.at(-1)!, /nichts geschrieben/)
  }
})
