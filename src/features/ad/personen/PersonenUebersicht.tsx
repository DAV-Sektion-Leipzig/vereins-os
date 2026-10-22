import { useState, type FormEvent } from 'react'
import { CircleAlertIcon, PlusIcon, RotateCwIcon, SearchIcon } from 'lucide-react'
import { Form, Link, useLoaderData, useNavigation, useRevalidator, useSubmit } from 'react-router-dom'
import { AccessStatusBadge } from '@/components/AccessStatusBadge'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAdAccess } from '@/features/ad/access'
import { NotfallHinweis } from '@/features/ad/personen/NotfallHinweis'
import {
  filterHref,
  MEMBERSHIP_FILTERS,
  VOLUNTEER_STATUS_LABELS,
  type OverviewResult,
  type PersonRow,
} from '@/features/ad/personen/data'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'
import type { AccessStatus } from '@/lib/rights'

const STATUS_FILTERS: Record<AccessStatus, string> = {
  none: 'kein Zugang',
  invited: 'eingeladen',
  active: 'aktiv',
  locked: 'gesperrt',
}

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:text-sm'

// T071 (US-AD-06, US-AD-15, US-AD-24): alle lesbaren Personen mit Zugang, Ehrenamtsstatus und Vorlagen.
export function PersonenUebersicht() {
  const { filter, rows, total, failed, emergency } = useLoaderData() as OverviewResult
  const { canEdit } = useAdAccess()
  const revalidator = useRevalidator()

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Personen</h1>
        {canEdit && (
          <Button asChild>
            <Link to="/ad/personen/neu">
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Person anlegen
            </Link>
          </Button>
        )}
      </div>

      {emergency && <NotfallHinweis notice={emergency} />}

      {/* key setzt das Suchfeld zurück, wenn der Filter über die Adresse wechselt (z. B. „Filter zurücksetzen“) */}
      <FilterForm key={filter.q} filter={filter} />

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
            rowKey={(p) => p.person_id}
            columns={COLUMNS}
            card={(p) => <PersonCard person={p} />}
            empty="Keine Personen gefunden."
            caption="Personen und Zugänge"
          />
          <Pagination page={filter.page} total={total} href={(page) => filterHref(filter, page)} label="Personen" />
        </>
      )}
    </section>
  )
}

function FilterForm({ filter }: { filter: OverviewResult['filter'] }) {
  const submit = useSubmit()
  const navigation = useNavigation()
  const [q, setQ] = useState(filter.q)

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    submit(event.currentTarget)
  }

  // Auswahlfelder lösen die Suche sofort aus; das Suchfeld beim Absenden (Enter oder Knopf)
  return (
    <Form method="get" action="/ad" onSubmit={onSubmit} className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
      <div className="flex min-w-0 flex-1 flex-col gap-2 sm:max-w-xs">
        <Label htmlFor="person-search">Suche</Label>
        <div className="flex gap-2">
          <Input
            id="person-search"
            name="q"
            type="search"
            value={q}
            onChange={(event) => setQ(event.target.value)}
            placeholder="Vor-, Ruf- oder Nachname"
            autoComplete="off"
          />
          <Button type="submit" variant="outline" aria-label="Suchen" disabled={navigation.state === 'loading'}>
            <SearchIcon aria-hidden="true" />
          </Button>
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="person-status">Zugangsstatus</Label>
        <select
          id="person-status"
          name="status"
          defaultValue={filter.status}
          onChange={(event) => submit(event.currentTarget.form)}
          className={selectClassName}
        >
          <option value="">alle</option>
          {(Object.keys(STATUS_FILTERS) as AccessStatus[]).map((s) => (
            <option key={s} value={s}>
              {STATUS_FILTERS[s]}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="person-membership">Zugehörigkeit</Label>
        <select
          id="person-membership"
          name="zugehoerigkeit"
          defaultValue={filter.membership}
          onChange={(event) => submit(event.currentTarget.form)}
          className={selectClassName}
        >
          <option value="">alle</option>
          {Object.entries(MEMBERSHIP_FILTERS).map(([key, label]) => (
            <option key={key} value={key}>
              {label}
            </option>
          ))}
        </select>
      </div>
      {(filter.q || filter.status || filter.membership) && (
        <Button variant="ghost" asChild className="self-start sm:self-auto">
          <Link to="/ad">Filter zurücksetzen</Link>
        </Button>
      )}
    </Form>
  )
}

function Name({ person }: { person: PersonRow }) {
  return (
    <span className="flex flex-wrap items-center gap-2">
      <Link to={`/ad/personen/${person.person_id}`} className="font-medium underline-offset-4 hover:underline">
        {personName(person)}
      </Link>
      {person.kind === 'function' && <Badge variant="outline">Funktionsperson</Badge>}
    </span>
  )
}

function VolunteerStatus({ person }: { person: PersonRow }) {
  if (!person.volunteer_status) return <span className="text-muted-foreground">–</span>
  return (
    <span>
      {VOLUNTEER_STATUS_LABELS[person.volunteer_status]}
      {person.volunteer_status_since && (
        <span className="text-muted-foreground"> seit {formatDate(person.volunteer_status_since)}</span>
      )}
    </span>
  )
}

function Templates({ person }: { person: PersonRow }) {
  if (person.templates.length === 0) return <span className="text-muted-foreground">–</span>
  return <span className="whitespace-normal">{person.templates.join(', ')}</span>
}

const COLUMNS: Column<PersonRow>[] = [
  { key: 'name', header: 'Name', cell: (p) => <Name person={p} /> },
  {
    key: 'email',
    header: 'Login-Adresse',
    cell: (p) => (p.login_email ? <span className="break-all">{p.login_email}</span> : <span className="text-muted-foreground">–</span>),
  },
  { key: 'status', header: 'Zugang', cell: (p) => <AccessStatusBadge status={p.access_status} /> },
  { key: 'volunteer', header: 'Ehrenamtsstatus', cell: (p) => <VolunteerStatus person={p} /> },
  { key: 'templates', header: 'Vorlagen', cell: (p) => <Templates person={p} />, className: 'whitespace-normal' },
  {
    key: 'open',
    header: <span className="sr-only">Aktion</span>,
    headerClassName: 'w-0',
    cell: (p) => (
      <Button variant="outline" asChild>
        <Link to={`/ad/personen/${p.person_id}`} aria-label={`${personName(p)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    ),
  },
]

function PersonCard({ person }: { person: PersonRow }) {
  return (
    <>
      <div className="flex flex-col gap-1">
        <Name person={person} />
        {person.login_email && <span className="text-sm break-all text-muted-foreground">{person.login_email}</span>}
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <AccessStatusBadge status={person.access_status} />
          {person.volunteer_status && (
            <span className="text-muted-foreground">
              Ehrenamt: <VolunteerStatus person={person} />
            </span>
          )}
        </div>
        {person.templates.length > 0 && (
          <span className="text-sm text-muted-foreground">Vorlagen: {person.templates.join(', ')}</span>
        )}
      </div>
      <Button variant="outline" asChild className="self-start">
        <Link to={`/ad/personen/${person.person_id}`} aria-label={`${personName(person)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    </>
  )
}
