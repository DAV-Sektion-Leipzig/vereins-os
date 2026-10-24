import { useState, type ReactNode } from 'react'
import { ChevronLeftIcon, CopyIcon, PencilIcon, PlusIcon, UserPlusIcon } from 'lucide-react'
import { Link, useLoaderData, useLocation, useRevalidator, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { useGrAccess } from '@/features/gr/access'
import {
  CONTRACT_STATUS_LABELS,
  GROUP_FUNCTIONS,
  isRunning,
  loadGuardianEmails,
  timeLabel,
  validOn,
  type FunctionRow,
  type GroupDetail,
  type GroupDetailResult,
  type MembershipRow,
  type TrainingTime,
} from '@/features/gr/gruppen/detail'
import { FunktionBeendenDialog, FunktionHinzufuegenDialog } from '@/features/gr/gruppen/FunktionDialog'
import { AufloesenDialog, GruppeAendernDialog } from '@/features/gr/gruppen/GruppeFormular'
import { TrainingszeitDialog, type TrainingTimeMode } from '@/features/gr/gruppen/TrainingszeitDialog'
import { FormError, HintBadge, LoadFailed } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { ageOn, formatDate, personName, todayIso } from '@/lib/format'
import { cn } from '@/lib/utils'

type Tab = 'teilnehmer' | 'betreuung' | 'trainingszeiten'
type MemberFilter = 'alle' | 'klaeren' | 'beendet'

const TABS: { id: Tab; label: string }[] = [
  { id: 'teilnehmer', label: 'Teilnehmer:innen' },
  { id: 'betreuung', label: 'Betreuung' },
  { id: 'trainingszeiten', label: 'Trainingszeiten' },
]

const NOT_FOUND = 'Gruppe nicht gefunden.'

// T032 (US-GR-05, US-GR-15): Gruppendetail mit Kopf (Referat, heutige Trainingszeiten, Betreuung) und den Reitern
// Teilnehmer:innen, Betreuung, Trainingszeiten; E-Mail-Adressen der Erziehungsberechtigten kopieren (T033).
export function GruppeDetailPage() {
  const result = useLoaderData() as GroupDetailResult
  const [params, setParams] = useSearchParams()
  const { canEdit } = useGrAccess()
  const revalidator = useRevalidator()
  const location = useLocation()
  const [dialog, setDialog] = useState<'edit' | 'dissolve' | null>(null)
  // Fehler beim Anlegen der ersten Trainingszeit (/gr/gruppen/neu)
  const carriedError = (location.state as { error?: string } | null)?.error ?? null
  const tab = (TABS.find((t) => t.id === params.get('reiter'))?.id ?? 'teilnehmer') as Tab

  if (result.state !== 'ok') {
    return (
      <section className="flex flex-col gap-4">
        <BackLink />
        <LoadFailed text={result.state === 'not_found' ? NOT_FOUND : MESSAGES.unexpected} />
      </section>
    )
  }

  const { group, trainingTimes, memberships, functions } = result
  const today = todayIso()
  const timesToday = trainingTimes.filter((t) => validOn(t.valid_from, t.valid_to, today))
  const currentFunctions = functions.filter((f) => validOn(f.valid_from, f.valid_to, today))

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-3">
        <BackLink />
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="flex flex-col gap-1">
            <h1 className="text-xl font-semibold">{group.name}</h1>
            <p className="text-sm text-muted-foreground">
              {group.referat_name}
              {group.dissolved_on && ` · aufgelöst am ${formatDate(group.dissolved_on)}`}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <EmailListButton groupId={group.id} />
            {canEdit && !group.dissolved_on && (
              <>
                <Button variant="outline" onClick={() => setDialog('edit')} className="h-11 sm:h-8">
                  <PencilIcon data-icon="inline-start" aria-hidden="true" />
                  Gruppe ändern
                </Button>
                <Button variant="destructive" onClick={() => setDialog('dissolve')} className="h-11 sm:h-8">
                  Gruppe auflösen
                </Button>
              </>
            )}
          </div>
        </div>
        <FormError text={carriedError} />
        <dl className="grid gap-x-6 gap-y-1 text-sm sm:grid-cols-[auto_1fr]">
          <dt className="text-muted-foreground">Trainingszeiten heute gültig</dt>
          <dd>{timesToday.length > 0 ? timesToday.map(timeLabel).join(' · ') : 'Keine Trainingszeit'}</dd>
          {GROUP_FUNCTIONS.map((fn) => {
            const names = currentFunctions.filter((f) => f.function === fn).map((f) => personName(f))
            return names.length > 0 ? (
              <FragmentRow key={fn} label={fn === 'Trainer:in' ? 'Trainer:innen' : fn === 'Helfer:in' ? 'Helfer:innen' : fn}>
                {names.join(', ')}
              </FragmentRow>
            ) : null
          })}
        </dl>
      </div>

      <div role="tablist" aria-label="Bereiche der Gruppe" className="flex flex-wrap gap-1 border-b">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            id={`gr-tab-${t.id}`}
            aria-selected={tab === t.id}
            aria-controls={`gr-panel-${t.id}`}
            onClick={() => setParams(t.id === 'teilnehmer' ? {} : { reiter: t.id }, { replace: true })}
            className={cn(
              '-mb-px inline-flex h-11 items-center border-b-2 px-3 text-sm outline-none focus-visible:ring-3 focus-visible:ring-ring/50 sm:h-9',
              tab === t.id ? 'border-primary font-medium' : 'border-transparent text-muted-foreground hover:text-foreground',
            )}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div role="tabpanel" id={`gr-panel-${tab}`} aria-labelledby={`gr-tab-${tab}`}>
        {tab === 'teilnehmer' && <MembersTab groupId={group.id} dissolved={Boolean(group.dissolved_on)} rows={memberships} />}
        {tab === 'betreuung' && (
          <FunctionsTab groupId={group.id} rows={functions} editable={canEdit && !group.dissolved_on} onChanged={() => revalidator.revalidate()} />
        )}
        {tab === 'trainingszeiten' && (
          <TrainingTimesTab group={group} rows={trainingTimes} editable={canEdit && !group.dissolved_on} onChanged={() => revalidator.revalidate()} />
        )}
      </div>

      {dialog === 'edit' && (
        <GruppeAendernDialog group={group} onClose={() => setDialog(null)} onDone={() => (setDialog(null), revalidator.revalidate())} />
      )}
      {dialog === 'dissolve' && (
        <AufloesenDialog group={group} onClose={() => setDialog(null)} onDone={() => (setDialog(null), revalidator.revalidate())} />
      )}
    </section>
  )
}

function FragmentRow({ label, children }: { label: string; children: ReactNode }) {
  return (
    <>
      <dt className="text-muted-foreground">{label}</dt>
      <dd>{children}</dd>
    </>
  )
}

function BackLink() {
  return (
    <Link to="/gr" className="inline-flex items-center gap-1 self-start text-sm text-muted-foreground hover:text-foreground">
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Gruppen
    </Link>
  )
}

// T033 (US-GR-15, R13): Adressen mit „; “ verbinden, in die Zwischenablage kopieren
function EmailListButton({ groupId }: { groupId: string }) {
  const [pending, setPending] = useState(false)

  async function copy() {
    setPending(true)
    const emails = await loadGuardianEmails(groupId)
    setPending(false)
    if (emails === null) return void toast.error(MESSAGES.unexpected)
    if (emails.length === 0) return void toast.info('Keine E-Mail-Adressen vorhanden.')
    try {
      await navigator.clipboard.writeText(emails.join('; '))
      toast.success(`${emails.length} ${emails.length === 1 ? 'Adresse' : 'Adressen'} kopiert. Bitte in Blindkopie (BCC) einfügen.`)
    } catch {
      toast.error(MESSAGES.unexpected)
    }
  }

  return (
    <Button variant="outline" onClick={() => void copy()} disabled={pending} className="h-11 sm:h-8">
      <CopyIcon data-icon="inline-start" aria-hidden="true" />
      {pending ? 'Wird geladen …' : 'E-Mail-Adressen kopieren'}
    </Button>
  )
}

// Teilnehmer:innen (US-GR-05): Alter nur bei lesbarem Geburtsdatum (W2); „beendet“ nur für den Admin,
// weil beendete Teilnahmen sonst nicht sichtbar sind (spec.md 6).
function MembersTab({ groupId, dissolved, rows }: { groupId: string; dissolved: boolean; rows: MembershipRow[] }) {
  const { canManage, isAdmin } = useGrAccess()
  const [filter, setFilter] = useState<MemberFilter>('alle')
  const today = todayIso()
  const showAge = rows.some((r) => r.birth_date !== null)
  const filtered = rows.filter((r) =>
    filter === 'klaeren' ? r.needs_clarification : filter === 'beendet' ? !isRunning(r.left_on, today) : isRunning(r.left_on, today),
  )
  const filters: { id: MemberFilter; label: string }[] = [
    { id: 'alle', label: 'alle' },
    { id: 'klaeren', label: 'Teilnahme klären' },
    ...(isAdmin ? [{ id: 'beendet' as const, label: 'beendet' }] : []),
  ]

  const columns: Column<MembershipRow>[] = [
    { key: 'name', header: 'Name', cell: (m) => <MemberName m={m} />, className: 'whitespace-normal' },
    ...(showAge
      ? [{ key: 'age', header: 'Alter', cell: (m: MembershipRow) => (m.birth_date ? ageOn(m.birth_date, today) : '–'), className: 'tabular-nums' }]
      : []),
    { key: 'joined', header: 'Eintritt', cell: (m) => formatDate(m.joined_on) },
    { key: 'contract', header: 'Vertrag', cell: (m) => <ContractCell m={m} /> },
    { key: 'photo', header: 'Fotoerlaubnis', cell: (m) => (m.photo_consent ? 'ja' : 'nein') },
    { key: 'hints', header: 'Hinweise', cell: (m) => <MemberHints m={m} />, className: 'whitespace-normal' },
  ]

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div role="group" aria-label="Filter Teilnehmer:innen" className="flex flex-wrap gap-1">
          {filters.map((f) => (
            <Button key={f.id} variant={filter === f.id ? 'secondary' : 'ghost'} aria-pressed={filter === f.id} onClick={() => setFilter(f.id)}>
              {f.label}
            </Button>
          ))}
        </div>
        {canManage && !dissolved && (
          <Button asChild className="h-11 sm:h-8">
            <Link to={`/gr/gruppen/${groupId}/aufnehmen`}>
              <UserPlusIcon data-icon="inline-start" aria-hidden="true" />
              Teilnehmer:in aufnehmen
            </Link>
          </Button>
        )}
      </div>
      <ResponsiveTable
        rows={filtered}
        rowKey={(m) => m.membership_id}
        columns={columns}
        card={(m) => (
          <div className="flex flex-col gap-1">
            <MemberName m={m} />
            <span className="text-sm text-muted-foreground">
              {[m.birth_date && `${ageOn(m.birth_date, today)} Jahre`, `seit ${formatDate(m.joined_on)}`, `Fotoerlaubnis ${m.photo_consent ? 'ja' : 'nein'}`]
                .filter(Boolean)
                .join(' · ')}
            </span>
            <span className="text-sm">
              Vertrag: <ContractCell m={m} />
            </span>
            <MemberHints m={m} />
          </div>
        )}
        empty={rows.length === 0 ? 'Noch keine Teilnehmer:innen.' : 'Keine Teilnehmer:innen für diesen Filter.'}
        caption="Teilnehmer:innen"
      />
    </div>
  )
}

function MemberName({ m }: { m: MembershipRow }) {
  return (
    <span className="flex flex-col gap-0.5">
      <Link to={`/gr/personen/${m.person_id}`} className="inline-flex min-h-11 items-center font-medium underline-offset-4 hover:underline sm:min-h-0">
        {personName(m)}
      </Link>
      {m.left_on && <span className="text-sm text-muted-foreground">Teilnahme bis {formatDate(m.left_on)}</span>}
    </span>
  )
}

function ContractCell({ m }: { m: MembershipRow }) {
  if (!m.contract_status) return <span className="text-muted-foreground">kein Vertrag</span>
  const label = CONTRACT_STATUS_LABELS[m.contract_status]
  if (m.contract_status === 'cancelled' && m.contract_ends_on) return <span>gekündigt zum {formatDate(m.contract_ends_on)}</span>
  return <span>{label}</span>
}

/** Hinweise R2, R7, R17 (keine Sperre). */
export function MemberHints({ m }: { m: Pick<MembershipRow, 'needs_clarification' | 'clarify_since' | 'has_emergency_contact' | 'needs_guardian' | 'left_on'> }) {
  const running = isRunning(m.left_on)
  const hints = [
    m.needs_clarification &&
      (m.clarify_since ? `Vertrag beendet am ${formatDate(m.clarify_since)} – Teilnahme klären.` : 'Teilnahme klären.'),
    running && !m.has_emergency_contact && 'Kein Notfallkontakt hinterlegt.',
    m.needs_guardian && 'Bitte mindestens eine erziehungsberechtigte Person angeben.',
  ].filter((h): h is string => Boolean(h))
  if (hints.length === 0) return <span className="text-muted-foreground">–</span>
  return (
    <span className="flex flex-wrap gap-1.5">
      {hints.map((h) => (
        <HintBadge key={h}>{h}</HintBadge>
      ))}
    </span>
  )
}

// Betreuung (US-GR-13): Funktionen mit seit/bis; beendete aufklappbar; Pflege nach T043
function FunctionsTab({
  groupId,
  rows,
  editable,
  onChanged,
}: {
  groupId: string
  rows: FunctionRow[]
  editable: boolean
  onChanged: () => void
}) {
  const today = todayIso()
  const current = rows.filter((f) => isRunning(f.valid_to, today))
  const ended = rows.filter((f) => !isRunning(f.valid_to, today))
  const [adding, setAdding] = useState(false)
  const [ending, setEnding] = useState<FunctionRow | null>(null)
  const actions = (f: FunctionRow) =>
    editable && (
      <Button variant="ghost" onClick={() => setEnding(f)} className="h-11 sm:h-8">
        {f.valid_to ? '„Bis“ ändern' : 'Beenden'}
      </Button>
    )

  return (
    <div className="flex flex-col gap-4">
      {editable && (
        <Button variant="outline" onClick={() => setAdding(true)} className="h-11 self-start sm:h-8">
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Funktion hinzufügen
        </Button>
      )}
      {current.length > 0 ? (
        <FunctionList rows={current} actions={actions} />
      ) : (
        <p className="text-sm text-muted-foreground">Noch keine Betreuung festgelegt.</p>
      )}
      {ended.length > 0 && (
        <details className="flex flex-col gap-2">
          <summary className="cursor-pointer text-sm text-muted-foreground">Beendete Funktionen ({ended.length})</summary>
          <FunctionList rows={ended} />
        </details>
      )}
      {adding && <FunktionHinzufuegenDialog groupId={groupId} onClose={() => setAdding(false)} onDone={() => (setAdding(false), onChanged())} />}
      {ending && <FunktionBeendenDialog row={ending} onClose={() => setEnding(null)} onDone={() => (setEnding(null), onChanged())} />}
    </div>
  )
}

function FunctionList({ rows, actions }: { rows: FunctionRow[]; actions?: (f: FunctionRow) => ReactNode }) {
  return (
    <ul className="flex flex-col divide-y rounded-xl border">
      {rows.map((f) => (
        <li key={f.id} className="flex flex-wrap items-center justify-between gap-2 px-4 py-3">
          <span className="flex flex-col gap-0.5">
            <Link to={`/gr/personen/${f.person_id}`} className="font-medium underline-offset-4 hover:underline">
              {personName(f)}
            </Link>
            <span className="text-sm text-muted-foreground">
              {f.function} · seit {formatDate(f.valid_from)}
              {f.valid_to && ` · bis ${formatDate(f.valid_to)}`}
            </span>
          </span>
          {actions?.(f)}
        </li>
      ))}
    </ul>
  )
}

// Trainingszeiten (US-GR-18): gültige, künftige mit „ab“, frühere aufklappbar; Pflege nach T029
function TrainingTimesTab({
  group,
  rows,
  editable,
  onChanged,
}: {
  group: GroupDetail
  rows: TrainingTime[]
  editable: boolean
  onChanged: () => void
}) {
  const today = todayIso()
  const [mode, setMode] = useState<TrainingTimeMode | null>(null)
  const dialog = mode && (
    <TrainingszeitDialog groupId={group.id} mode={mode} onClose={() => setMode(null)} onDone={() => (setMode(null), onChanged())} />
  )
  const addButton = editable && (
    <Button variant="outline" onClick={() => setMode({ kind: 'add' })} className="h-11 self-start sm:h-8">
      <PlusIcon data-icon="inline-start" aria-hidden="true" />
      Trainingszeit hinzufügen
    </Button>
  )
  const actions = (t: TrainingTime) =>
    editable && (
      <span className="flex flex-wrap gap-2">
        <Button variant="outline" onClick={() => setMode({ kind: 'change', time: t })} className="h-11 sm:h-8">
          Ändern ab
        </Button>
        <Button variant="ghost" onClick={() => setMode({ kind: 'end', time: t })} className="h-11 sm:h-8">
          {t.valid_to ? '„Gültig bis“ ändern' : 'Beenden'}
        </Button>
      </span>
    )
  const current = rows.filter((t) => validOn(t.valid_from, t.valid_to, today))
  const future = rows.filter((t) => t.valid_from > today)
  const past = rows.filter((t) => t.valid_to !== null && t.valid_to < today)

  if (rows.length === 0)
    return (
      <div className="flex flex-col gap-4">
        <p className="text-sm text-muted-foreground">Keine Trainingszeit.</p>
        {addButton}
        {dialog}
      </div>
    )
  return (
    <div className="flex flex-col gap-4">
      {addButton}
      {current.length + future.length > 0 ? (
        <TimeList rows={[...current, ...future]} today={today} actions={actions} />
      ) : (
        <p className="text-sm text-muted-foreground">Keine Trainingszeit.</p>
      )}
      {past.length > 0 && (
        <details className="flex flex-col gap-2">
          <summary className="cursor-pointer text-sm text-muted-foreground">Frühere Trainingszeiten ({past.length})</summary>
          <TimeList rows={past} today={today} />
        </details>
      )}
      {dialog}
    </div>
  )
}

function TimeList({ rows, today, actions }: { rows: TrainingTime[]; today: string; actions?: (t: TrainingTime) => ReactNode }) {
  return (
    <ul className="flex flex-col divide-y rounded-xl border">
      {rows.map((t) => (
        <li key={t.id} className="flex flex-wrap items-center justify-between gap-2 px-4 py-3">
          <span className="flex flex-col gap-0.5">
            <span className="font-medium">{timeLabel(t)}</span>
            <span className="text-sm text-muted-foreground">
              {t.valid_from > today ? `ab ${formatDate(t.valid_from)}` : `gültig von ${formatDate(t.valid_from)}`}
              {t.valid_to && ` bis ${formatDate(t.valid_to)}`}
            </span>
          </span>
          {actions?.(t)}
        </li>
      ))}
    </ul>
  )
}
