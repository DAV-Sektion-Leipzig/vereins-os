import { useEffect, useRef, useState, type FormEvent } from 'react'
import { CircleAlertIcon, PlusIcon, RotateCwIcon, TriangleAlertIcon } from 'lucide-react'
import { Form, Link, useLoaderData, useRevalidator, useSubmit } from 'react-router-dom'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useEaAccess } from '@/features/ea/access'
import {
  filterHref,
  hasActiveFilter,
  VOLUNTEER_STATUS_LABELS,
  type ExpiryKind,
  type VolunteerRow,
  type VolunteersResult,
} from '@/features/ea/aktive/data'
import { Filterleiste } from '@/features/ea/aktive/Filterleiste'
import { AblaufBadge } from '@/features/ea/shared/AblaufBadge'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'

const SEARCH_DELAY_MS = 300

// T035 (US-EA-02, US-EA-03): Übersicht der Aktiven aus ea_volunteer_list, 50 je Seite.
export function AktivePage() {
  const { filter, options, rows, total, failed } = useLoaderData() as VolunteersResult
  const access = useEaAccess()
  const revalidator = useRevalidator()
  const canCreate = access.canEdit || access.myReferate.length > 0

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Aktive</h1>
        {canCreate && (
          <Button asChild>
            <Link to="/ea/aktive/neu">
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Person anlegen
            </Link>
          </Button>
        )}
      </div>

      <SearchForm result={{ filter, options }} showReset={hasActiveFilter(filter, access)} />

      {failed ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {MESSAGES.unexpected}
          </p>
          <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
            <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
            {revalidator.state === 'loading' ? 'Wird geladen …' : 'Erneut laden'}
          </Button>
        </div>
      ) : (
        <>
          <ResponsiveTable
            rows={rows}
            rowKey={(p) => p.id}
            columns={COLUMNS}
            card={(p) => <VolunteerCard person={p} />}
            empty="Keine Aktiven gefunden."
            caption="Aktive"
          />
          <Pagination page={filter.page} total={total} href={(page) => filterHref(filter, page)} label="Aktiven" />
        </>
      )}
    </section>
  )
}

type SearchFormProps = { result: Pick<VolunteersResult, 'filter' | 'options'>; showReset: boolean }

// Suche ab 1 Zeichen mit 300 ms Verzögerung (spec.md EA Abschnitt 6); Filter lösen sofort aus.
function SearchForm({ result: { filter, options }, showReset }: SearchFormProps) {
  const submit = useSubmit()
  const formRef = useRef<HTMLFormElement>(null)
  const [q, setQ] = useState(filter.q)
  const submitted = useRef(filter.q)

  // Suchbegriff von außen geändert (z. B. „Filter zurücksetzen“, Zurück im Browser)
  useEffect(() => {
    if (filter.q !== submitted.current) {
      submitted.current = filter.q
      setQ(filter.q)
    }
  }, [filter.q])

  useEffect(() => {
    if (q.trim() === submitted.current) return
    const timer = window.setTimeout(() => {
      submitted.current = q.trim()
      submit(formRef.current, { replace: true })
    }, SEARCH_DELAY_MS)
    return () => window.clearTimeout(timer)
  }, [q, submit])

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    submitted.current = q.trim()
    submit(event.currentTarget, { replace: true })
  }

  return (
    <Form ref={formRef} method="get" action="/ea/aktive" onSubmit={onSubmit} className="flex flex-col gap-4">
      <div className="flex flex-col gap-2 sm:max-w-xs">
        <Label htmlFor="ea-search">Suche</Label>
        <Input
          id="ea-search"
          name="q"
          type="search"
          value={q}
          onChange={(event) => setQ(event.target.value)}
          placeholder="Vor-, Ruf- oder Nachname"
          autoComplete="off"
        />
      </div>
      {/* key setzt die Filterfelder zurück, wenn sich die Filter über die Adresse ändern */}
      <Filterleiste key={filterHref({ ...filter, q: '' }, 1)} filter={filter} options={options}>
        {showReset && (
          <Button variant="ghost" asChild className="self-start">
            <Link to="/ea/aktive">Filter zurücksetzen</Link>
          </Button>
        )}
      </Filterleiste>
    </Form>
  )
}

function Name({ person }: { person: VolunteerRow }) {
  return (
    <Link to={`/ea/aktive/${person.id}`} className="font-medium underline-offset-4 hover:underline">
      {personName(person)}
    </Link>
  )
}

const MAX_EXPIRIES = 2

const EXPIRY_KIND_LABELS: Record<ExpiryKind, string> = {
  license: 'Lizenz',
  qualification: 'Qualifikation',
  police_clearance: 'Führungszeugnis',
}

// Ablauf an einer Stelle: schlechtester Status (Badge), darunter was abgelaufen ist oder bald abläuft,
// dazu das Kennzeichen „ohne gültige Lizenz“.
function Ablauf({ person }: { person: VolunteerRow }) {
  if (person.worst_expiry === 'none' && !person.trainer_without_license) return <AblaufBadge status="none" />
  const shown = person.expiries.length > MAX_EXPIRIES ? person.expiries.slice(0, MAX_EXPIRIES - 1) : person.expiries
  const more = person.expiries.length - shown.length
  return (
    <span className="flex flex-col items-start gap-1">
      {person.worst_expiry !== 'none' && <AblaufBadge status={person.worst_expiry} />}
      {shown.map((e) => (
        <span key={e.propertyId} className="text-xs text-muted-foreground">
          {[EXPIRY_KIND_LABELS[e.kind], e.code].filter(Boolean).join(' ')} · {formatDate(e.validUntil)}
          {e.status === 'expiring' && person.worst_expiry === 'expired' && ' (läuft bald ab)'}
        </span>
      ))}
      {more > 0 && <span className="text-xs text-muted-foreground">+ {more} weitere</span>}
      {person.trainer_without_license && <WithoutLicense />}
    </span>
  )
}

function WithoutLicense() {
  return (
    <Badge className="bg-destructive/10 text-destructive">
      <TriangleAlertIcon data-icon="inline-start" aria-hidden="true" />
      ohne gültige Lizenz
    </Badge>
  )
}

function Status({ person }: { person: VolunteerRow }) {
  return (
    <span>
      {VOLUNTEER_STATUS_LABELS[person.volunteer_status]}
      <span className="text-muted-foreground"> seit {formatDate(person.volunteer_status_since)}</span>
    </span>
  )
}

function List({ values }: { values: string[] }) {
  if (values.length === 0) return <span className="text-muted-foreground">–</span>
  return <span className="whitespace-normal">{values.join(', ')}</span>
}

const COLUMNS: Column<VolunteerRow>[] = [
  { key: 'name', header: 'Name', cell: (p) => <Name person={p} />, className: 'whitespace-normal' },
  { key: 'status', header: 'Status', cell: (p) => <Status person={p} /> },
  { key: 'referate', header: 'Referate', cell: (p) => <List values={p.referate} />, className: 'whitespace-normal' },
  {
    key: 'functions',
    header: 'Funktionen und Ämter',
    cell: (p) => <List values={[...p.functions, ...p.positions]} />,
    className: 'whitespace-normal',
  },
  { key: 'licenses', header: 'Lizenzen', cell: (p) => <List values={p.license_codes} /> },
  { key: 'expiry', header: 'Ablauf', cell: (p) => <Ablauf person={p} />, className: 'whitespace-normal' },
  {
    key: 'open',
    header: <span className="sr-only">Aktion</span>,
    headerClassName: 'w-0',
    cell: (p) => (
      <Button variant="outline" asChild>
        <Link to={`/ea/aktive/${p.id}`} aria-label={`${personName(p)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    ),
  },
]

function VolunteerCard({ person }: { person: VolunteerRow }) {
  const assignments = [...person.functions, ...person.positions]
  return (
    <>
      <div className="flex flex-col gap-1">
        <Name person={person} />
        <span className="text-sm">
          <Status person={person} />
        </span>
        {assignments.length > 0 && <span className="text-sm text-muted-foreground">{assignments.join(', ')}</span>}
        {person.referate.length > 0 && (
          <span className="text-sm text-muted-foreground">Referate: {person.referate.join(', ')}</span>
        )}
        {person.license_codes.length > 0 && (
          <span className="text-sm text-muted-foreground">Lizenzen: {person.license_codes.join(', ')}</span>
        )}
        {(person.worst_expiry !== 'none' || person.trainer_without_license) && (
          <span className="text-sm">
            <Ablauf person={person} />
          </span>
        )}
      </div>
      <Button variant="outline" asChild className="self-start">
        <Link to={`/ea/aktive/${person.id}`} aria-label={`${personName(person)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    </>
  )
}
