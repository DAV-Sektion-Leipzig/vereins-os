import { useState } from 'react'
import { ChevronLeftIcon, CircleAlertIcon, CircleCheckIcon, CircleDashedIcon, CircleMinusIcon, TriangleAlertIcon, type LucideIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import type { PersonProperty, PropertyTypeWithFields } from '@/features/ad/personen/data'
import { EigenschaftenAbschnitt } from '@/features/ad/personen/EigenschaftenAbschnitt'
import { qualificationLabel } from '@/features/ad/qualifikationsarten/data'
import { useEaAccess } from '@/features/ea/access'
import { Section } from '@/features/ad/personen/Section'
import {
  deriveValidUntil,
  NOT_FOUND_MESSAGE,
  VOLUNTEER_STATUS_LABELS,
  type StatusHistoryEntry,
  type VolunteerDetailResult,
  type VolunteerStatus,
} from '@/features/ea/aktive/data'
import { StatusDialog } from '@/features/ea/aktive/StatusDialog'
import { VerlaengernDialog } from '@/features/ea/aktive/VerlaengernDialog'
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

/** Verlängerbare Systemarten (R6). */
const RENEW_KINDS = ['license', 'qualification']

const today = () => new Date().toISOString().slice(0, 10)

// T039 (US-EA-04, US-EA-11): Kopf mit Status und Historie, Eigenschaften mit „sichtbar in“ EA nach Kategorie.
// T042, T044 (US-EA-06, US-EA-07): Pflegen und Verlängern, soweit ea_property_writable es erlaubt.
export function PersonDetailPage() {
  const result = useLoaderData() as VolunteerDetailResult
  const revalidator = useRevalidator()
  const navigate = useNavigate()
  const { canEdit, myReferate } = useEaAccess()
  const [renewing, setRenewing] = useState<{ property: PersonProperty; type: PropertyTypeWithFields } | null>(null)
  const [changingStatus, setChangingStatus] = useState(false)

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

  const { person, history, historyNames, properties, expiry, trainerWithoutLicense, writable, addableTypeIds, restrictReferate } =
    result

  /** „Verlängern“ nur bei aktuellen Lizenzen und Qualifikationen mit Qualifikationsart „aktuell“ (spec.md v0.2.1, O2). */
  function canRenew(p: PersonProperty, t: PropertyTypeWithFields) {
    if (!t.system_key || !RENEW_KINDS.includes(t.system_key) || !properties) return false
    const current = p.valid_from <= today() && (!p.valid_to || p.valid_to >= today())
    const q = properties.qualificationTypes.find((x) => x.id === p.field_values.qualification_type)
    return current && q?.status === 'current'
  }

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
          {person.volunteer_status && (canEdit || myReferate.length > 0) && (
            <Button variant="outline" size="sm" onClick={() => setChangingStatus(true)}>
              Status ändern
            </Button>
          )}
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
          canEdit={canEdit || myReferate.length > 0}
          module="EA"
          isWritable={(p) => writable[p.id] === true}
          addableTypeIds={addableTypeIds}
          restrictReferate={restrictReferate}
          onDerive={deriveValidUntil}
          renderExtra={(p, t) =>
            t.system_key && EXPIRY_KINDS.includes(t.system_key) && expiry[p.id] ? <AblaufBadge status={expiry[p.id]} /> : null
          }
          renderActions={(p, t) =>
            canRenew(p, t) ? (
              <Button variant="outline" size="sm" onClick={() => setRenewing({ property: p, type: t })}>
                Verlängern
              </Button>
            ) : null
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

      {changingStatus && person.volunteer_status && (
        <StatusDialog
          personId={person.id}
          personName={personName(person)}
          current={person.volunteer_status}
          properties={properties}
          writable={writable}
          ownReferate={restrictReferate}
          onClose={() => setChangingStatus(false)}
          onDone={(status) => {
            setChangingStatus(false)
            // Ausgeschiedene sieht die Referent:in nicht mehr (US-EA-09 AK5): zurück zur Übersicht
            if (status === 'left' && restrictReferate) navigate('/ea/aktive', { replace: true })
            else revalidator.revalidate()
          }}
        />
      )}

      {renewing && properties && (
        <VerlaengernDialog
          property={renewing.property}
          type={renewing.type}
          qualificationLabel={(() => {
            const q = properties.qualificationTypes.find((x) => x.id === renewing.property.field_values.qualification_type)
            return q ? qualificationLabel(q) : renewing.type.name
          })()}
          onClose={() => setRenewing(null)}
          onDone={() => {
            setRenewing(null)
            revalidator.revalidate()
          }}
        />
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
