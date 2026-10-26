import { HISTORY_LABELS, STATUS_LABELS, TRACKED_FIELD_LABELS } from '@/features/tk/labels'
import type { HistoryEntry } from '@/features/tk/types'
import { formatDateTime } from '@/lib/format'

// Verlauf (spec.md TK 2 tk_plan_history, R19): wer, wann, Kommentar; ab Freigabe geänderte Felder ohne Werte.
export function Verlauf({ entries }: { entries: HistoryEntry[] }) {
  if (entries.length === 0) return <p className="text-sm text-muted-foreground">Noch keine Einträge.</p>
  return (
    <ol className="flex flex-col gap-3">
      {[...entries].reverse().map((h, i) => (
        <li key={i} className="flex flex-col gap-0.5 border-l-2 pl-3 text-sm">
          <span>
            <span className="font-medium">{HISTORY_LABELS[h.event] ?? h.event}</span>
            {h.to_status && h.event !== 'created' && h.event !== 'copied' && h.from_status && (
              <span className="text-muted-foreground"> ({STATUS_LABELS[h.from_status]} → {STATUS_LABELS[h.to_status]})</span>
            )}
          </span>
          <span className="text-xs text-muted-foreground">
            {formatDateTime(h.at)}
            {h.by_name ? ` · ${h.by_name}` : ''}
          </span>
          {h.changed_fields && h.changed_fields.length > 0 && (
            <span className="text-xs">Geändert: {h.changed_fields.map((f) => TRACKED_FIELD_LABELS[f] ?? f).join(', ')}</span>
          )}
          {h.comment && <span className="whitespace-pre-line">{h.comment}</span>}
        </li>
      ))}
    </ol>
  )
}
