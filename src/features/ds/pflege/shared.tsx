// Gemeinsame Bausteine der Budgetpflege: Datei wählen, Ergebnis-Hinweise, Aufruf mit Neuladen.
import { useRef, useState, type ReactNode } from 'react'
import { UploadIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { dsRpc } from '@/features/ds/errors'

export function FilePick({ accept, label, onFile, disabled }: { accept: string; label: string; onFile: (file: File) => void; disabled?: boolean }) {
  const ref = useRef<HTMLInputElement>(null)
  return (
    <>
      <input
        ref={ref}
        type="file"
        accept={accept}
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          const file = e.target.files?.[0]
          e.target.value = ''
          if (file) onFile(file)
        }}
      />
      <Button variant="outline" disabled={disabled} onClick={() => ref.current?.click()}>
        <UploadIcon data-icon="inline-start" aria-hidden="true" />
        {label}
      </Button>
    </>
  )
}

export function Note({ tone = 'info', children }: { tone?: 'info' | 'warn' | 'ok'; children: ReactNode }) {
  const cls =
    tone === 'warn'
      ? 'border-status-locked/40 bg-status-locked-bg text-status-locked'
      : tone === 'ok'
        ? 'border-status-active/30 bg-status-active-bg text-status-active'
        : 'border-status-invited/30 bg-status-invited-bg text-status-invited'
  return <div className={`rounded-lg border px-3 py-2 text-sm ${cls}`}>{children}</div>
}

/** Schreibender Aufruf mit Fehlermeldung und Neuladen der Seite. */
export function useAction() {
  const revalidator = useRevalidator()
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  /** null bei Fehler (Meldung in error), sonst { data } – auch bei Funktionen ohne Rückgabewert. */
  async function run<T>(fn: string, args: Record<string, unknown>, reload = true): Promise<{ data: T } | null> {
    setPending(true)
    setError(null)
    const res = await dsRpc<T>(fn, args)
    setPending(false)
    if (res.error) {
      setError(res.error.text)
      return null
    }
    if (reload) revalidator.revalidate()
    return { data: res.data }
  }
  return { pending, error, setError, run }
}

export const RULE_STATUS: Record<string, string> = { ok: 'ok', uncertain: 'unsicher', open: 'offen', no_booking: 'keine Buchung' }

export const LOG_ACTIONS: Record<string, string> = {
  plan_import: 'Finanzplan eingelesen',
  group_set: 'Sichtbarkeit geändert',
  item_move: 'Gesamtbudget eines Postens geändert',
  rule_save: 'Regel gespeichert',
  rule_end: 'Regel beendet',
  rules_csv_import: 'zuordnung.csv übernommen',
  year_from_previous: 'Aus dem Vorjahr übernommen',
  booking_import: 'DATEV-Export eingespielt',
  rekey: 'Umgeschlüsselt',
  rekey_undo: 'Umschlüsselung zurückgenommen',
  proposal_create: 'Umschlüsselung vorgeschlagen',
  proposal_withdraw: 'Vorschlag zurückgezogen',
  proposal_accept: 'Vorschlag angenommen',
  proposal_reject: 'Vorschlag abgelehnt',
  note: 'Hinweis gespeichert',
  realloc_request: 'Umschichtung beantragt',
  realloc_confirm: 'Umschichtung bestätigt',
  realloc_reject: 'Umschichtung abgelehnt',
  realloc_withdraw: 'Umschichtung zurückgezogen',
  payout_mark: 'Auszahlungsrunde markiert',
  purge: 'Löschlauf',
  purge_failed: 'Löschlauf fehlgeschlagen',
}
