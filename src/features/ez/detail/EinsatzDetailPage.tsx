import { useState, type ReactNode } from 'react'
import { BanIcon, CheckCheckIcon, LockIcon, PencilIcon, RotateCcwIcon, Trash2Icon, UserPlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { AbsageDialog } from '@/features/ez/detail/AbsageDialog'
import {
  attendanceInput,
  eventHead,
  type Attendance,
  type EventDetail,
  type EventDetailResult,
} from '@/features/ez/detail/data'
import { NeuePersonDialog } from '@/features/ez/detail/NeuePersonDialog'
import { PersonHinzufuegenDialog } from '@/features/ez/detail/PersonHinzufuegenDialog'
import { EZ_MESSAGES } from '@/features/ez/errors'
import { formatEventDate, hhmm, weekdayShort } from '@/features/ez/dates'
import {
  DAY_LABELS,
  KIND_LABELS,
  STATUS_LABELS,
  usesStatus,
  type AttendanceStatus,
  type Role,
} from '@/features/ez/labels'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { ezRpc, nameOf, type PersonNames } from '@/features/ez/shared/rpc'
import { SettledBadge } from '@/features/ez/shared/SettledBadge'
import { FormError } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'
import { cn } from '@/lib/utils'

type Dialog = 'cancel' | 'restore' | 'delete' | 'add' | 'new' | null

// T029, T031 (US-EZ-10, -12, -13, -15, -22, -23): Kopf, Anwesenheit nach Rolle mit Stand und Kennzeichen,
// Bearbeiten, Absagen bzw. Absage zurücknehmen, Löschen (nur Geschäftsstelle); bei Arbeitseinsatz, Kurs und Tour
// Stände direkt setzen, „alle anwesend“, „Person hinzufügen“, beim Arbeitseinsatz „Neue Person anlegen“.
export function EinsatzDetailPage() {
  const result = useLoaderData() as EventDetailResult
  if (!result.detail) {
    return (
      <section className="flex flex-col gap-4">
        <h1 className="text-xl font-semibold">Einsatz</h1>
        <p role="alert" className="text-sm text-muted-foreground">
          {EZ_MESSAGES.notFound}
        </p>
        <Button variant="outline" asChild className="self-start">
          <Link to="/ez">Zur Liste</Link>
        </Button>
      </section>
    )
  }
  return <Detail detail={result.detail} names={result.names} />
}

function Detail({ detail, names }: { detail: EventDetail; names: PersonNames }) {
  const { event: e } = detail
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const [dialog, setDialog] = useState<Dialog>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const writable = detail.can_write && !e.is_cancelled
  const statusMode = usesStatus(e.kind)
  const title = e.kind === 'training' ? detail.groups.map((g) => g.name).join(' + ') : e.title

  async function saveAttendances(next: Pick<Attendance, 'person_id' | 'role' | 'status'>[]): Promise<string | null> {
    setPending(true)
    const res = await ezRpc('ez_save_event', {
      p_event: eventHead(e),
      p_attendances: attendanceInput(next),
      p_trials: detail.trials.map((t) => t.first_name),
    })
    setPending(false)
    if (res.error) return res.error.text
    revalidator.revalidate()
    return null
  }

  async function setStatus(personId: string, status: AttendanceStatus) {
    setError(await saveAttendances(detail.attendances.map((a) => (a.person_id === personId ? { ...a, status } : a))))
  }

  async function allPresent() {
    // „alle anwesend“ setzt nur „eingetragen“ → „anwesend“; „nicht erschienen“ bleibt (spec.md 4)
    setError(await saveAttendances(detail.attendances.map((a) => (a.status === 'registered' ? { ...a, status: 'present' } : a))))
  }

  async function onDelete() {
    setPending(true)
    const res = await ezRpc('ez_delete_event', { p_id: e.id })
    setPending(false)
    if (res.error) return setError(res.error.code === 'EZ_DELETE_FORBIDDEN' ? res.error.text : EZ_MESSAGES.deleteFailed)
    toast.success('Der Einsatz wurde gelöscht.')
    navigate('/ez')
  }

  async function onRestore() {
    setPending(true)
    const res = await ezRpc('ez_restore_event', { p_id: e.id })
    setPending(false)
    if (res.error) return setError(res.error.text)
    setDialog(null)
    revalidator.revalidate()
  }

  const closeDialog = () => {
    setDialog(null)
    setError(null)
  }

  return (
    <section className="flex flex-col gap-6">
      <header className="flex flex-col gap-3">
        <div className="flex flex-col gap-1">
          <span className="text-sm text-muted-foreground">{KIND_LABELS[e.kind]}</span>
          <h1 className={cn('text-xl font-semibold text-balance', e.is_cancelled && 'text-muted-foreground line-through')}>
            {title || KIND_LABELS[e.kind]}
          </h1>
          <div className="flex flex-wrap gap-1.5">
            {e.is_cancelled && <Badge variant="outline">abgesagt</Badge>}
            {e.from_planning && <Badge variant="outline">aus der Planungshilfe</Badge>}
            {e.is_settled && <SettledBadge />}
          </div>
        </div>

        {e.is_cancelled && (
          <p className="rounded-lg border border-destructive/30 bg-destructive/5 p-3 text-sm">
            Abgesagt am {e.cancelled_at ? formatDate(e.cancelled_at) : '–'} von {nameOf(names, e.cancelled_by_person_id)}: {e.cancel_reason}
          </p>
        )}
        {e.from_planning && (
          <p className="rounded-lg border bg-muted/50 p-3 text-sm">
            Aus der Planungshilfe Touren und Kurse. Kopf und Personen aus der Planung werden dort geändert.
          </p>
        )}
        {e.is_settled && (
          <p className="flex gap-2 rounded-lg border bg-muted/50 p-3 text-sm">
            <LockIcon className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            {EZ_MESSAGES.settled}
          </p>
        )}

        <Actions
          detail={detail}
          onCancel={() => setDialog('cancel')}
          onRestore={() => setDialog('restore')}
          onDelete={() => setDialog('delete')}
        />
      </header>

      <Kopf detail={detail} names={names} />

      <section aria-labelledby="ez-attendance" className="flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 id="ez-attendance" className="text-lg font-semibold">
            Anwesenheit
          </h2>
          {statusMode && writable && (
            <div className="flex flex-wrap gap-2">
              {detail.attendances.some((a) => a.status === 'registered') && (
                <Button variant="outline" onClick={allPresent} disabled={pending}>
                  <CheckCheckIcon data-icon="inline-start" aria-hidden="true" />
                  alle anwesend
                </Button>
              )}
              <Button variant="outline" onClick={() => setDialog('add')} disabled={pending}>
                <UserPlusIcon data-icon="inline-start" aria-hidden="true" />
                Person hinzufügen
              </Button>
              {e.kind === 'work_assignment' && (
                <Button variant="outline" onClick={() => setDialog('new')} disabled={pending}>
                  <UserPlusIcon data-icon="inline-start" aria-hidden="true" />
                  Neue Person anlegen
                </Button>
              )}
            </div>
          )}
        </div>
        <FormError text={dialog ? null : error} />
        <AttendanceList
          attendances={detail.attendances}
          names={names}
          statusMode={statusMode}
          writable={writable}
          pending={pending}
          onStatus={setStatus}
        />
        {detail.trials.length > 0 && (
          <div className="flex flex-col gap-1.5">
            <h3 className="text-sm font-medium text-muted-foreground">Probetraining ({detail.trials.length})</h3>
            <p className="text-sm">{detail.trials.map((t) => t.first_name).join(', ')}</p>
          </div>
        )}
      </section>

      {dialog === 'cancel' && (
        <AbsageDialog
          eventId={e.id}
          onClose={closeDialog}
          onDone={() => {
            closeDialog()
            revalidator.revalidate()
          }}
        />
      )}
      {dialog === 'restore' && (
        <ConfirmDialog
          title="Absage zurücknehmen?"
          confirmLabel="Absage zurücknehmen"
          pendingLabel="Wird zurückgenommen …"
          pending={pending}
          error={error}
          onConfirm={onRestore}
          onClose={closeDialog}
        >
          Danach ist der Einsatz wieder erfasst und änderbar.
        </ConfirmDialog>
      )}
      {dialog === 'delete' && (
        <ConfirmDialog
          title="Einsatz und alle Anwesenheiten löschen?"
          confirmLabel="Löschen"
          pendingLabel="Wird gelöscht …"
          pending={pending}
          error={error}
          destructive
          onConfirm={onDelete}
          onClose={closeDialog}
        >
          Die Personen bleiben erhalten. Das Löschen kann nicht rückgängig gemacht werden.
        </ConfirmDialog>
      )}
      {dialog === 'add' && (
        <PersonHinzufuegenDialog
          kind={e.kind}
          excludeIds={detail.attendances.map((a) => a.person_id)}
          onClose={closeDialog}
          onAdd={async (personId: string, role: Role) => {
            const message = await saveAttendances([...detail.attendances, { person_id: personId, role, status: 'present' }])
            if (!message) closeDialog()
            return message
          }}
        />
      )}
      {dialog === 'new' && (
        <NeuePersonDialog
          eventId={e.id}
          attendances={detail.attendances}
          onClose={closeDialog}
          onAddExisting={async (personId: string) =>
            saveAttendances([...detail.attendances, { person_id: personId, role: 'helper', status: 'present' }])
          }
          onDone={() => {
            closeDialog()
            revalidator.revalidate()
          }}
        />
      )}
    </section>
  )
}

function Actions({
  detail,
  onCancel,
  onRestore,
  onDelete,
}: {
  detail: EventDetail
  onCancel: () => void
  onRestore: () => void
  onDelete: () => void
}) {
  const { event: e } = detail
  const buttons: ReactNode[] = []
  if (detail.can_write && !e.is_cancelled) {
    buttons.push(
      <Button key="edit" asChild>
        <Link to={`/ez/${e.id}/bearbeiten`}>
          <PencilIcon data-icon="inline-start" aria-hidden="true" />
          Bearbeiten
        </Link>
      </Button>,
    )
  }
  // Einsätze aus der Planungshilfe: kein Absagen, kein Löschen (R25)
  if (detail.can_write && !e.from_planning && !e.is_cancelled) {
    buttons.push(
      <Button key="cancel" variant="outline" onClick={onCancel} disabled={e.is_settled}>
        <BanIcon data-icon="inline-start" aria-hidden="true" />
        Absagen
      </Button>,
    )
  }
  if (detail.can_write && !e.from_planning && e.is_cancelled) {
    buttons.push(
      <Button key="restore" variant="outline" onClick={onRestore}>
        <RotateCcwIcon data-icon="inline-start" aria-hidden="true" />
        Absage zurücknehmen
      </Button>,
    )
  }
  if (detail.can_delete && !e.from_planning) {
    buttons.push(
      <Button key="delete" variant="destructive" onClick={onDelete} disabled={e.is_settled}>
        <Trash2Icon data-icon="inline-start" aria-hidden="true" />
        Löschen
      </Button>,
    )
  }
  if (buttons.length === 0) return null
  return <div className="flex flex-wrap gap-2">{buttons}</div>
}

/** Datum mit Wochentag bzw. Zeitraum mit Abfahrt und Rückkehr am Startort (R3, R4, R28). */
function dateText(detail: EventDetail): string {
  const e = detail.event
  if (e.span === 'multi') {
    const start = `${formatDate(e.start_date)}${e.start_time ? ` ${hhmm(e.start_time)}` : ''}`
    const end = e.end_date ? `${formatDate(e.end_date)}${e.end_time ? ` ${hhmm(e.end_time)}` : ''}` : ''
    return `${start} – ${end}`
  }
  return `${weekdayShort(e.start_date)} ${formatEventDate(e.start_date, null)}`
}

function Kopf({ detail, names }: { detail: EventDetail; names: PersonNames }) {
  const e = detail.event
  const rows: [string, ReactNode][] = [
    ['Referat', detail.referat_name],
    ...(detail.groups.length > 0
      ? [[detail.groups.length > 1 ? 'Gruppen' : 'Gruppe', detail.groups.map((g) => g.name).join(', ')] as [string, ReactNode]]
      : []),
    [e.span === 'multi' ? 'Zeitraum' : 'Datum', dateText(detail)],
    ...(e.day_category ? [['Dauer', DAY_LABELS[e.day_category]] as [string, ReactNode]] : []),
    ...(detail.location_name ? [['Ort', detail.location_name] as [string, ReactNode]] : []),
    ...(e.organizer_person_id ? [['Organisierende Person', nameOf(names, e.organizer_person_id)] as [string, ReactNode]] : []),
    ['Vergütung', e.remuneration_kind_name ?? 'keine Vergütung'],
    ...(e.remark ? [['Bemerkung', <span key="remark" className="whitespace-pre-line">{e.remark}</span>] as [string, ReactNode]] : []),
    ['Erfasst', `${formatDateTime(e.created_at)} von ${nameOf(names, e.created_by_person_id)}`],
    ...(e.updated_at
      ? [['Geändert', `${formatDateTime(e.updated_at)} von ${nameOf(names, e.updated_by_person_id)}`] as [string, ReactNode]]
      : []),
  ]
  return (
    <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
      {rows.map(([label, value]) => (
        <div key={label} className="contents">
          <dt className="text-muted-foreground">{label}</dt>
          <dd className="mb-2 sm:mb-0">{value}</dd>
        </div>
      ))}
    </dl>
  )
}

const ROLE_ORDER: Role[] = ['trainer', 'helper', 'participant']
const ROLE_SECTIONS: Record<Role, string> = { trainer: 'Trainer:innen', helper: 'Helfer:innen', participant: 'Teilnehmer:innen' }

function AttendanceList({
  attendances,
  names,
  statusMode,
  writable,
  pending,
  onStatus,
}: {
  attendances: Attendance[]
  names: PersonNames
  statusMode: boolean
  writable: boolean
  pending: boolean
  onStatus: (personId: string, status: AttendanceStatus) => void
}) {
  if (attendances.length === 0) return <p className="text-sm text-muted-foreground">Noch keine Personen eingetragen.</p>
  const byName = (a: Attendance, b: Attendance) => nameOf(names, a.person_id).localeCompare(nameOf(names, b.person_id), 'de-DE')

  return (
    <div className="flex flex-col gap-4">
      {ROLE_ORDER.map((role) => {
        const list = attendances.filter((a) => a.role === role).sort(byName)
        if (list.length === 0) return null
        return (
          <div key={role} className="flex flex-col gap-1.5">
            <h3 className="text-sm font-medium text-muted-foreground">
              {ROLE_SECTIONS[role]} ({list.length})
            </h3>
            <ul className="flex flex-col divide-y rounded-xl border">
              {list.map((a) => (
                <li key={a.id} className="flex flex-col gap-2 px-3 py-2.5 sm:flex-row sm:items-center sm:justify-between">
                  <div className="flex flex-wrap items-center gap-1.5">
                    <span className="font-medium">{nameOf(names, a.person_id)}</span>
                    {a.is_substitute && <Badge variant="outline">Vertretung</Badge>}
                    {a.from_plan && <Badge variant="outline">aus der Planung</Badge>}
                    {a.is_settled && <SettledBadge />}
                    {statusMode && !writable && <span className="text-sm text-muted-foreground">{STATUS_LABELS[a.status]}</span>}
                  </div>
                  {statusMode && writable && (
                    <div role="group" aria-label={`Stand von ${nameOf(names, a.person_id)}`} className="flex gap-2">
                      {(['present', 'absent'] as AttendanceStatus[]).map((s) => (
                        <Button
                          key={s}
                          size="sm"
                          variant={a.status === s ? 'default' : 'outline'}
                          aria-pressed={a.status === s}
                          disabled={pending || a.is_settled}
                          onClick={() => a.status !== s && onStatus(a.person_id, s)}
                          className="h-11 sm:h-8"
                        >
                          {STATUS_LABELS[s]}
                        </Button>
                      ))}
                      {a.status === 'registered' && (
                        <span className="self-center text-sm text-muted-foreground">{STATUS_LABELS.registered}</span>
                      )}
                    </div>
                  )}
                </li>
              ))}
            </ul>
          </div>
        )
      })}
    </div>
  )
}
