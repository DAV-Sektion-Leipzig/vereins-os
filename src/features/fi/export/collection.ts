// FT24 (US-FI-19, -21, R40–R43): Lastschriftdatei (XML) und Einzugsliste (PDF) aus demselben fi_collection_export;
// im Browser erzeugt und heruntergeladen, nichts wird gespeichert.
import { toast } from 'sonner'
import { fiRpc } from '@/features/fi/rpc'
import { downloadBlob } from '@/features/fi/export/pdf'
import { buildPain008, debitProblems, type CollectionExport } from '@/features/fi/export/sepaDebit'

export type CollectionFilesResult = { error: string | null; bankChanged: string[] }

export async function downloadCollectionFiles(runId: string): Promise<CollectionFilesResult> {
  const res = await fiRpc<CollectionExport>('fi_collection_export', { p_run: runId })
  if (res.error) return { error: res.error.text, bankChanged: [] }
  const data = res.data
  const problems = debitProblems(data)
  if (problems.length > 0) return { error: problems.join(' '), bankChanged: [] }
  try {
    const { buildCollectionList } = await import('@/features/fi/export/collectionList')
    const base = `Vertraege_${data.run.month.slice(0, 4)}_${data.run.month.slice(5, 7)}_Lauf${data.run.number}`
    const pdf = await buildCollectionList(data)
    downloadBlob(pdf, `Einzugsliste_${base}.pdf`)
    downloadBlob(new Blob([buildPain008(data)], { type: 'application/xml;charset=utf-8' }), `Lastschriften_${base}.xml`)
  } catch {
    return { error: 'Die Dateien konnten nicht erzeugt werden. Bitte erneut versuchen.', bankChanged: [] }
  }
  return {
    error: null,
    bankChanged: data.lines.filter((l) => l.bank_changed).map((l) => `${l.participant_first_name} ${l.participant_last_name}`),
  }
}

/** Hinweis nach dem Download (H2.3) und Warnung bei geänderter Bankverbindung (R43). */
export function reportCollectionDownload(bankChanged: string[]) {
  toast.success(
    'Einzugsliste und Lastschriftdatei wurden heruntergeladen. Bitte die Lastschriftdatei nach dem Hochladen im Online-Banking von diesem Rechner löschen.',
    { duration: 12_000 },
  )
  if (bankChanged.length > 0) {
    toast.warning(`Bankverbindung seit der Freigabe geändert: ${bankChanged.join(', ')}. Bitte die Lastschriften prüfen.`, {
      duration: 20_000,
    })
  }
}
