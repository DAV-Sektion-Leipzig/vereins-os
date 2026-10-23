import { ChevronLeftIcon, CircleAlertIcon, CircleCheckIcon, CircleDashedIcon, CircleMinusIcon, TriangleAlertIcon, type LucideIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { EigenschaftenAbschnitt } from '@/features/ad/personen/EigenschaftenAbschnitt'
import { Section } from '@/features/ad/personen/Section'
import {
  NOT_FOUND_MESSAGE,
  VOLUNTEER_STATUS_LABELS,
  type StatusHistoryEntry,
  type VolunteerDetailResult,
  type VolunteerStatus,
} from '@/features/ea/aktive/data'
import { AblaufBadge } from '@/features/ea/shared/AblaufBadge'
import { MESSAGES } from '@/lib/errors'
import { formatDate, formatDateTime, personName } from '@/lib/format'

const STATUS_STYLE: Record<VolunteerStatus, { icon: LucideIcon; className: string }> = {
  active: { icon: CircleCheckIcon, className: 'bg-status-active-bg text-status-active' },
  dormant: { icon: CircleDashedIcon, className: 'bg-status-none-bg text-status-none' },
  left: { icon: CircleMinusIcon, className: 'bg-status-locked-bg text-status-locked' },
}

/** Systemarten mit Ablaufstatus (R9, R10). */
const EXPIRY_KINDS = ['license', 'qualification', 'police_clearance']

// T039 (US-EA-04, US-EA-11): Kopf mit Status und Historie, Eigenschaften mit „sichtbar in“ EA nach Kategorie.
// Bearbeiten folgt mit US-EA-06 (Phase 8); bis dahin nur lesen.
export function PersonDetailPage() {
  const result = useLoaderData() as VolunteerDetailResult
  const revalidator = useRevalidator()

  if (result.state !== 'ok') {
    return (
      <section className="flex flex-col gap-4">
        <BackLink />
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {result.state === 'not_found' ? NOT_FOUND_MESSAGE : MESSAGES.unexpected}
        </p>
        {result.state === 'failed' && (
          <Button variant="outline" className="self-start" onClick={() => revalidator.revalidate()}>
            Erneut laden
          </Button>
        )}
      </section>
    )
  }

  const { person, history, historyNames, properties, expiry, trainerWithoutLicense } = result

  return (
    <section className="flex flex-col gap-8">
      <div className="flex flex-col gap-3">
        <BackLink />
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold">{personName(person)}</h1>
          {person.preferred_name && (
            <p className="text-sm text-muted-foreground">
              Vorname {person.first_name} · Rufname {person.preferred_name}
            </p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge status={person.volunteer_status} since={person.volunteer_status_since} />
          {trainerWithoutLicense && (
            <Badge className="bg-destructive/10 text-destructive">
              <TriangleAlertIcon data-icon="inline-start" aria-hidden="true" />
              Trainer:in ohne gültige Lizenz
            </Badge>
          )}
        </div>
        {history.length > 0 && <StatusHistory entries={history} names={historyNames} />}
      </div>

      {properties ? (
        <EigenschaftenAbschnitt
          personId={person.id}
          data={properties}
          canEdit={false}
          module="EA"
          renderExtra={(p, t) =>
            t.system_key && EXPIRY_KINDS.includes(t.system_key) && expiry[p.id] ? <AblaufBadge status={expiry[p.id]} /> : null
          }
        />
      ) : (
        <Section id="eigenschaften" title="Eigenschaften">
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {MESSAGES.unexpected}
          </p>
        </Section>
      )}
    </section>
  )
}

function StatusBadge({ status, since }: { status: VolunteerStatus | null; since: string | null }) {
  if (!status) return <Badge variant="outline">ohne Ehrenamtsstatus</Badge>
  const { icon: Icon, className } = STATUS_STYLE[status]
  return (
    <Badge className={className}>
      <Icon data-icon="inline-start" aria-hidden="true" />
      {VOLUNTEER_STATUS_LABELS[status]}
      {since && ` seit ${formatDate(since)}`}
    </Badge>
  )
}

function StatusHistory({ entries, names }: { entries: StatusHistoryEntry[]; names: Record<string, string> }) {
  return (
    <details className="text-sm">
      <summary className="cursor-pointer self-start text-muted-foreground">
        Statushistorie ({entries.length} {entries.length === 1 ? 'Eintrag' : 'Einträge'})
      </summary>
      <ol className="mt-2 flex flex-col gap-2 border-l-2 pl-3">
        {entries.map((h) => (
          <li key={h.id} className="flex flex-col gap-0.5">
            <span>
              {VOLUNTEER_STATUS_LABELS[h.status]} ab {formatDate(h.valid_from)}
            </span>
            <span className="text-xs text-muted-foreground">
              gesetzt am {formatDateTime(h.set_at)}
              {names[h.set_by ?? ''] && ` von ${names[h.set_by!]}`}
            </span>
          </li>
        ))}
      </ol>
    </details>
  )
}

function BackLink() {
  return (
    <Link
      to="/ea/aktive"
      className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    >
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Aktive
    </Link>
  )
}
