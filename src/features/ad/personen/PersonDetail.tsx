import { ChevronLeftIcon, CircleAlertIcon } from 'lucide-react'
import { Link, useLoaderData, useLocation } from 'react-router-dom'
import { AccessStatusBadge } from '@/components/AccessStatusBadge'
import { useAdAccess } from '@/features/ad/access'
import { EigenschaftenAbschnitt } from '@/features/ad/personen/EigenschaftenAbschnitt'
import { RechtevorlagenAbschnitt } from '@/features/ad/personen/RechtevorlagenAbschnitt'
import { Section } from '@/features/ad/personen/Section'
import { StammdatenAbschnitt } from '@/features/ad/personen/StammdatenAbschnitt'
import type { DetailResult } from '@/features/ad/personen/data'
import { MESSAGES } from '@/lib/errors'
import { personName } from '@/lib/format'

// T075 (US-AD-24; Gerüst für US-AD-08, 09, 11, 13): Personendetail mit den Abschnitten aus spec.md Abschnitt 6.
export function PersonDetail() {
  const { person, properties, assignments, failed } = useLoaderData() as DetailResult
  const { canEdit } = useAdAccess()
  const location = useLocation()
  const handedError = (location.state as { error?: string } | null)?.error ?? null

  if (failed || !person) {
    return (
      <section className="flex flex-col gap-4">
        <BackLink />
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
      </section>
    )
  }

  return (
    <section className="flex flex-col gap-8">
      <div className="flex flex-col gap-2">
        <BackLink />
        <h1 className="flex flex-wrap items-center gap-3 text-xl font-semibold">
          {personName(person)}
          <AccessStatusBadge status={person.access_status} />
        </h1>
        {handedError && (
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {handedError}
          </p>
        )}
      </div>

      <StammdatenAbschnitt person={person} canEdit={canEdit} />

      <Section id="zugang" title="Zugang">
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
          <dt className="text-muted-foreground">Login-Adresse</dt>
          <dd>{person.login_email ?? '–'}</dd>
          <dt className="text-muted-foreground">Status</dt>
          <dd>
            <AccessStatusBadge status={person.access_status} />
          </dd>
        </dl>
        <p className="text-sm text-muted-foreground">Einladen, Sperren und Adresse ändern folgen.</p>
      </Section>

      {assignments ? (
        <RechtevorlagenAbschnitt personId={person.person_id} data={assignments} canEdit={canEdit} />
      ) : (
        <Section id="rechtevorlagen" title="Rechtevorlagen">
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {MESSAGES.unexpected}
          </p>
        </Section>
      )}

      {properties ? (
        <EigenschaftenAbschnitt personId={person.person_id} data={properties} canEdit={canEdit} />
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

function BackLink() {
  return (
    <Link
      to="/ad"
      className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    >
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Personen
    </Link>
  )
}
