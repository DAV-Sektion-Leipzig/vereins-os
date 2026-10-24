import { useState, type FormEvent } from 'react'
import { InfoIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { currentConsent, type ConsentRow, type HealthHistoryRow } from '@/features/gr/personen/data'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime, todayIso } from '@/lib/format'

const HEALTH_HINT =
  'Nur erfassen, wenn eine schriftliche Einwilligung der Erziehungsberechtigten vorliegt. Nur Angaben, die für Training und Ausfahrten nötig sind.'

/** Ja/Nein mit Datum und Historie (R12, R24); jede Änderung ist eine neue Zeile. */
function ConsentEditor({
  id,
  label,
  rows,
  editable,
  rpcName,
  personId,
  onChanged,
}: {
  id: string
  label: string
  rows: ConsentRow[]
  editable: boolean
  rpcName: 'gr_set_photo_consent' | 'gr_set_health_consent'
  personId: string
  onChanged: () => void
}) {
  const current = currentConsent(rows)
  const [editing, setEditing] = useState(false)
  const [date, setDate] = useState(todayIso())
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setPending(true)
    setError(null)
    const result = await grRpc(rpcName, { p_person: personId, p_granted: !current, p_effective_on: date || null })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    setEditing(false)
    onChanged()
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-3">
        <span>
          {label}: <span className="font-medium">{current ? 'ja' : 'nein'}</span>
          {rows[0] && <span className="text-sm text-muted-foreground"> seit {formatDate(rows[0].effective_on)}</span>}
        </span>
        {editable && !editing && (
          <Button variant="outline" onClick={() => setEditing(true)} className="h-11 sm:h-8">
            {current ? 'Auf „nein“ setzen' : 'Auf „ja“ setzen'}
          </Button>
        )}
      </div>
      {editing && (
        <form onSubmit={onSubmit} noValidate className="flex flex-wrap items-end gap-3">
          <div className="flex flex-col gap-2">
            <Label htmlFor={`${id}-date`}>Datum ({current ? 'Widerruf' : 'Erteilung'})</Label>
            <Input id={`${id}-date`} type="date" max={todayIso()} value={date} onChange={(e) => setDate(e.target.value)} className="sm:w-44" />
          </div>
          <Button type="submit" disabled={pending} className="h-11 sm:h-8">
            {pending ? 'Speichern …' : `„${current ? 'nein' : 'ja'}“ speichern`}
          </Button>
          <Button type="button" variant="ghost" onClick={() => setEditing(false)} disabled={pending} className="h-11 sm:h-8">
            Abbrechen
          </Button>
        </form>
      )}
      <FormError text={error} />
      {rows.length > 1 && (
        <details>
          <summary className="cursor-pointer text-sm text-muted-foreground">Frühere Stände ({rows.length - 1})</summary>
          <ul className="mt-2 flex flex-col gap-1 text-sm">
            {rows.slice(1).map((r) => (
              <li key={r.id}>
                {r.granted ? 'ja' : 'nein'} ab {formatDate(r.effective_on)}{' '}
                <span className="text-muted-foreground">(erfasst {formatDateTime(r.created_at)})</span>
              </li>
            ))}
          </ul>
        </details>
      )}
    </div>
  )
}

// T040 (US-GR-10): Fotoerlaubnis
export function FotoerlaubnisAbschnitt(props: { personId: string; rows: ConsentRow[]; editable: boolean; onChanged: () => void }) {
  return <ConsentEditor id="gr-photo" label="Fotoerlaubnis" rpcName="gr_set_photo_consent" {...props} />
}

// T040 (US-GR-12, R11, R24): Einwilligung und Gesundheitsangaben, nur mit „Gruppen bearbeiten“
export function GesundheitAbschnitt({
  personId,
  consents,
  note,
  history,
  onChanged,
}: {
  personId: string
  consents: ConsentRow[]
  note: { note: string; updated_at: string } | null
  history: HealthHistoryRow[]
  onChanged: () => void
}) {
  const granted = currentConsent(consents)
  const [text, setText] = useState(note?.note ?? '')
  const [editing, setEditing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function save(event: FormEvent) {
    event.preventDefault()
    setPending(true)
    setError(null)
    const result = await grRpc('gr_save_health_note', { p_person: personId, p_note: text })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    setEditing(false)
    onChanged()
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="flex items-start gap-2 text-sm text-muted-foreground">
        <InfoIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0" />
        {HEALTH_HINT}
      </p>
      <ConsentEditor
        id="gr-health-consent"
        label="Einwilligung zu Gesundheitsangaben"
        rows={consents}
        editable
        rpcName="gr_set_health_consent"
        personId={personId}
        onChanged={onChanged}
      />
      {granted &&
        (editing ? (
          <form onSubmit={save} noValidate className="flex flex-col gap-2">
            <Label htmlFor="gr-health-note">Gesundheitliche Einschränkungen</Label>
            <textarea
              id="gr-health-note"
              value={text}
              maxLength={2000}
              rows={4}
              onChange={(e) => setText(e.target.value)}
              className="w-full rounded-lg border border-input bg-background px-2.5 py-2 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
            />
            <span className="text-sm text-muted-foreground">{text.length} / 2000</span>
            <span className="flex flex-wrap gap-2">
              <Button type="submit" disabled={pending} className="h-11 sm:h-8">
                {pending ? 'Speichern …' : 'Speichern'}
              </Button>
              <Button type="button" variant="ghost" onClick={() => setEditing(false)} disabled={pending} className="h-11 sm:h-8">
                Abbrechen
              </Button>
            </span>
          </form>
        ) : (
          <div className="flex flex-col gap-2">
            <span className="text-sm text-muted-foreground">Gesundheitliche Einschränkungen</span>
            <p className="whitespace-pre-wrap">{note?.note ?? 'Keine Angaben erfasst.'}</p>
            <Button variant="outline" onClick={() => (setText(note?.note ?? ''), setEditing(true))} className="h-11 self-start sm:h-8">
              {note ? 'Ändern' : 'Erfassen'}
            </Button>
          </div>
        ))}
      <FormError text={error} />
      {granted && history.length > 0 && (
        <details>
          <summary className="cursor-pointer text-sm text-muted-foreground">Frühere Fassungen ({history.length})</summary>
          <ul className="mt-2 flex flex-col gap-2 text-sm">
            {history.map((h) => (
              <li key={h.id} className="flex flex-col">
                <span className="text-muted-foreground">
                  {formatDateTime(h.valid_since)} bis {formatDateTime(h.replaced_at)}
                </span>
                <span className="whitespace-pre-wrap">{h.note}</span>
              </li>
            ))}
          </ul>
        </details>
      )}
    </div>
  )
}
