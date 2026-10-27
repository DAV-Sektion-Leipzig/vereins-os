// Prüf- bzw. Abschlussbericht als Markdown (contracts/migration-script.md „Berichte“; T024).
// Enthält Namen und bleibt lokal (.gitignore); der Secret Key wird nie übergeben und kommt nie vor.
import type { Finding } from './csv.ts'

export type ImportResult = {
  /** code nur bei Befunden mit fester Bedeutung, z. B. EA_IMPORT_ALREADY_RUN (Wiederholungsschutz) */
  errors: (Finding & { code?: string })[]
  warnings: Finding[]
  counts: Record<string, number>
  written: boolean
}

export type ReportInput = {
  file: string
  projectRef: string
  cutoff: string
  at: Date
  mode: 'dry-run' | 'run'
  formatErrors: Finding[]
  result: ImportResult | null
}

const byRow = (a: Finding, b: Finding) => a.row - b.row || a.message.localeCompare(b.message, 'de')

function list(items: Finding[], empty: string): string {
  return items.length === 0 ? `_${empty}_` : [...items].sort(byRow).map((f) => `- ${f.message}`).join('\n')
}

function formatDate(iso: string) {
  const [y, m, d] = iso.split('-')
  return `${d}.${m}.${y}`
}

export function buildReport(input: ReportInput): string {
  const { result } = input
  const errors = [...input.formatErrors, ...(result?.errors ?? [])]
  const counts = result?.counts ?? {}
  const kinds = Object.entries(counts)
    .filter(([k]) => k !== 'persons' && k !== 'valid_from_cutoff')
    .sort(([a], [b]) => a.localeCompare(b))

  return [
    `# ${input.mode === 'run' ? 'Abschlussbericht' : 'Prüfbericht'} Migration der Aktivenliste`,
    '',
    `- Datei: ${input.file}`,
    `- Projekt: ${input.projectRef}`,
    `- Stichtag: ${formatDate(input.cutoff)}`,
    `- Zeitpunkt: ${input.at.toLocaleString('de-DE', { timeZone: 'Europe/Berlin' })}`,
    `- Art: ${input.mode === 'run' ? 'Lauf' : 'Probelauf'}${result ? (result.written ? ' – geschrieben' : ' – nichts geschrieben') : ''}`,
    '',
    `## Fehler (${errors.length})`,
    '',
    list(errors, 'keine'),
    '',
    `## Warnungen (${result?.warnings.length ?? 0})`,
    '',
    list(result?.warnings ?? [], 'keine'),
    '',
    '## Zusammenfassung',
    '',
    `- Personen: ${counts.persons ?? 0}`,
    ...kinds.map(([k, n]) => `- ${k}: ${n}`),
    `- Eigenschaften mit „gültig von“ = Stichtag: ${counts.valid_from_cutoff ?? 0}`,
    '',
  ].join('\n')
}
