// Ablauf des Migrationsskripts (spec.md Abschnitt 7, contracts/migration-script.md, research.md R-EA-11; T025).
// Ein- und Ausgabe sowie der RPC-Aufruf kommen von außen, damit sich der Ablauf ohne Datenbank testen lässt.
import { MissingColumnError, parseCsv, type ImportRow } from './csv.ts'
import { buildReport, type ImportResult } from './report.ts'

export type Rpc = (rows: ImportRow[], cutoff: string, dryRun: boolean) => Promise<ImportResult>

export type Io = {
  readFile: (path: string) => Promise<string>
  writeFile: (path: string, content: string) => Promise<void>
  ask: (question: string) => Promise<string>
  /** Eingabe ohne Anzeige (Secret Key) */
  askHidden: (question: string) => Promise<string>
  log: (message: string) => void
  /** Client mit Projekt-URL und Schlüssel; der Schlüssel verlässt diese Funktion nicht */
  connect: (url: string, key: string) => Rpc
  now: () => Date
}

export type Args = { file: string; mode: 'dry-run' | 'run'; cutoff: string }

const USAGE = 'Aufruf: npm run ea:migrate -- --file <pfad> --dry-run|--run [--cutoff TT.MM.JJJJ]'

/** Exitcodes: 0 Probelauf ohne Fehler bzw. Lauf geschrieben; 1 Befunde oder Abbruch; 2 falscher Aufruf. */
export const EXIT = { ok: 0, findings: 1, usage: 2 } as const

function toIso(value: string): string | null {
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(value)
  if (!m) return null
  return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`
}

export function parseArgs(argv: string[], today: Date): Args | string {
  const get = (flag: string) => {
    const i = argv.indexOf(flag)
    return i >= 0 ? argv[i + 1] : undefined
  }
  const dry = argv.includes('--dry-run')
  const run = argv.includes('--run')
  const file = get('--file')
  if (!file || dry === run) return USAGE
  const cutoffArg = get('--cutoff')
  const cutoff = cutoffArg ? toIso(cutoffArg) : today.toISOString().slice(0, 10)
  if (!cutoff) return `Stichtag ${cutoffArg} nicht lesbar (TT.MM.JJJJ).`
  return { file, mode: dry ? 'dry-run' : 'run', cutoff }
}

/** Project Ref aus https://<ref>.supabase.co */
export function projectRef(url: string): string | null {
  const m = /^https:\/\/([a-z0-9]{20})\.supabase\.co\/?$/.exec(url.trim())
  return m ? m[1] : null
}

function reportPath(file: string, kind: 'pruefbericht' | 'abschlussbericht') {
  return `${file.replace(/\.csv$/i, '')}.${kind}.md`
}

export async function main(argv: string[], io: Io): Promise<number> {
  const args = parseArgs(argv, io.now())
  if (typeof args === 'string') {
    io.log(args)
    return EXIT.usage
  }

  // CSV zuerst lesen: fehlende Spalte bricht ohne Bericht ab (US-EA-17 AK5)
  let parsed
  try {
    parsed = parseCsv(await io.readFile(args.file))
  } catch (error) {
    io.log(error instanceof MissingColumnError ? error.message : `Datei ${args.file} nicht lesbar.`)
    return EXIT.findings
  }

  const url = (await io.ask('Projekt-URL: ')).trim()
  const ref = projectRef(url)
  if (!ref) {
    io.log('Projekt-URL ungültig (erwartet https://<ref>.supabase.co).')
    return EXIT.usage
  }
  const key = (await io.askHidden('Secret Key: ')).trim()
  if (!key) {
    io.log('Schlüssel fehlt.')
    return EXIT.usage
  }

  if (args.mode === 'run') {
    const confirm = (await io.ask(`Lauf gegen ${ref} – zum Bestätigen Projekt-Ref eingeben: `)).trim()
    if (confirm !== ref) {
      io.log('Projekt-Ref stimmt nicht. Lauf abgebrochen.')
      return EXIT.findings
    }
  }

  const rpc = io.connect(url, key)
  const report = (mode: Args['mode'], result: ImportResult | null) =>
    buildReport({ file: args.file, projectRef: ref, cutoff: args.cutoff, at: io.now(), mode, formatErrors: parsed.formatErrors, result })

  let dry: ImportResult
  try {
    dry = await rpc(parsed.rows, args.cutoff, true)
  } catch (error) {
    io.log(`Aufruf fehlgeschlagen: ${error instanceof Error ? error.message : 'unbekannter Fehler'}`)
    return EXIT.findings
  }
  const hasErrors = parsed.formatErrors.length > 0 || dry.errors.length > 0
  const dryPath = reportPath(args.file, 'pruefbericht')
  await io.writeFile(dryPath, report('dry-run', dry))

  if (args.mode === 'dry-run') {
    io.log(`Prüfbericht: ${dryPath} (${parsed.formatErrors.length + dry.errors.length} Fehler, ${dry.warnings.length} Warnungen)`)
    return hasErrors ? EXIT.findings : EXIT.ok
  }

  if (hasErrors) {
    io.log(`Probelauf hat Fehler. Lauf abgebrochen. Prüfbericht: ${dryPath}`)
    return EXIT.findings
  }

  let result: ImportResult
  try {
    result = await rpc(parsed.rows, args.cutoff, false)
  } catch (error) {
    io.log(`Aufruf fehlgeschlagen, nichts geschrieben: ${error instanceof Error ? error.message : 'unbekannter Fehler'}`)
    return EXIT.findings
  }
  const runPath = reportPath(args.file, 'abschlussbericht')
  await io.writeFile(runPath, report('run', result))
  io.log(`Abschlussbericht: ${runPath} (${result.written ? 'geschrieben' : 'nichts geschrieben'})`)
  return result.written ? EXIT.ok : EXIT.findings
}
