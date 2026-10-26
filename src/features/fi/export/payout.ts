// FT14 (US-FI-15, -16, R21, R28, R29): Auszahlliste (PDF) und Überweisungsdatei (XML) aus demselben fi_payout_export;
// im Browser erzeugt und heruntergeladen, nichts wird gespeichert.
import { toast } from 'sonner'
import { FI_MESSAGES } from '@/features/fi/errors'
import { fiRpc } from '@/features/fi/rpc'
import { downloadBlob } from '@/features/fi/export/pdf'
import { buildPain001, sepaProblems, type PayoutExport } from '@/features/fi/export/sepa'

export type PayoutFilesResult = {
  error: string | null
  /** Personen, deren Bankverbindung sich seit der Freigabe geändert hat (R21). */
  bankChanged: string[]
}

export async function downloadPayoutFiles(runId: string): Promise<PayoutFilesResult> {
  const res = await fiRpc<PayoutExport>('fi_payout_export', { p_run: runId })
  if (res.error) return { error: res.error.text, bankChanged: [] }
  const data = res.data
  const problems = sepaProblems(data)
  if (problems.length > 0) return { error: problems.join(' '), bankChanged: [] }
  try {
    const { buildPayoutList } = await import('@/features/fi/export/payoutList')
    const base = `UEL_${data.run.year}_${data.run.half}_Runde${data.run.number}`
    const pdf = await buildPayoutList(data)
    downloadBlob(pdf, `Auszahlliste_${base}.pdf`)
    downloadBlob(new Blob([buildPain001(data)], { type: 'application/xml;charset=utf-8' }), `Ueberweisungen_${base}.xml`)
  } catch {
    return { error: 'Die Dateien konnten nicht erzeugt werden. Bitte erneut versuchen.', bankChanged: [] }
  }
  return {
    error: null,
    bankChanged: data.lines.filter((l) => l.bank_changed).map((l) => `${l.first_name} ${l.last_name}`),
  }
}

/** Hinweis nach dem Download (spec.md FI 6) und Warnung bei geänderter Bankverbindung (R21). */
export function reportDownload(bankChanged: string[]) {
  toast.success(`Auszahlliste und Überweisungsdatei wurden heruntergeladen. ${FI_MESSAGES.deleteXmlHint}`, { duration: 12_000 })
  if (bankChanged.length > 0) {
    toast.warning(`Bankverbindung seit der Freigabe geändert: ${bankChanged.join(', ')}. Bitte die Überweisungen prüfen.`, { duration: 20_000 })
  }
}
