// Migrationsskript der Aktivenliste (US-EA-17, US-EA-18; T025). Aufruf siehe run.ts.
// Der Secret Key wird verdeckt abgefragt, lebt nur im Arbeitsspeicher und wird nie geloggt oder gespeichert
// (spec.md v0.2.1 Abschnitt 7); kein Lesen aus process.env oder Dateien.
import { readFile, writeFile } from 'node:fs/promises'
import { createInterface } from 'node:readline'
import { Writable } from 'node:stream'
import { createClient } from '@supabase/supabase-js'
import type { ImportRow } from './csv.ts'
import type { ImportResult } from './report.ts'
import { main, RpcError, type Io } from './run.ts'

let muted = false
const output = new Writable({
  write(chunk, _encoding, callback) {
    if (!muted) process.stdout.write(chunk)
    callback()
  },
})
const rl = createInterface({ input: process.stdin, output, terminal: true })

function ask(question: string): Promise<string> {
  return new Promise((resolve) => rl.question(question, resolve))
}

async function askHidden(question: string): Promise<string> {
  process.stdout.write(question)
  muted = true
  try {
    return await ask('')
  } finally {
    muted = false
    process.stdout.write('\n')
  }
}

const io: Io = {
  readFile: (path) => readFile(path, 'utf8'),
  writeFile: (path, content) => writeFile(path, content, 'utf8'),
  ask,
  askHidden,
  log: (message) => console.log(message),
  connect(url, key) {
    const client = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
    return async (rows: ImportRow[], cutoff: string, dryRun: boolean) => {
      const { data, error } = await client.rpc('ea_import_volunteers', { p_rows: rows, p_cutoff: cutoff, p_dry_run: dryRun })
      // nur Meldung und Fehlercode weitergeben, keine Header oder Konfiguration; ohne Code (Netzwerk, Timeout)
      // gilt das Ergebnis als unbekannt (run.ts)
      if (error) throw new RpcError(error.message, error.code || undefined)
      return data as ImportResult
    }
  },
  now: () => new Date(),
}

main(process.argv.slice(2), io)
  .then((code) => {
    rl.close()
    process.exitCode = code
  })
  .catch((error: unknown) => {
    rl.close()
    console.error(error instanceof Error ? error.message : 'Unbekannter Fehler.')
    process.exitCode = 1
  })
