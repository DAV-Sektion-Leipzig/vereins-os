import { CircleAlertIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import type { GremienResult, Membership } from '@/features/ea/gremien/data'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'

const name = (m: Membership) => personName({ first_name: m.firstName, preferred_name: m.preferredName, last_name: m.lastName })
const dash = <span className="text-muted-foreground">–</span>

// T049 (US-EA-13): je aktivem Gremium (Reihenfolge sort_order) die heute gültigen Mitgliedschaften.
export function GremienPage() {
  const { gremien, failed } = useLoaderData() as GremienResult
  const revalidator = useRevalidator()

  return (
    <section className="flex flex-col gap-6">
      <h1 className="text-xl font-semibold">Gremien</h1>

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
        gremien.map((g) => (
          <section key={g.id} aria-labelledby={`gremium-${g.id}`} className="flex flex-col gap-2">
            <h2 id={`gremium-${g.id}`} className="font-medium">
              {g.name}
            </h2>
            <ResponsiveTable
              rows={g.members}
              rowKey={(m) => m.id}
              columns={COLUMNS}
              card={(m) => <MemberCard member={m} />}
              empty="Keine Mitglieder eingetragen."
              caption={`Mitglieder ${g.name}`}
            />
          </section>
        ))
      )}
    </section>
  )
}

function NameLink({ member }: { member: Membership }) {
  return (
    <Link to={`/ea/aktive/${member.personId}`} className="font-medium underline-offset-4 hover:underline">
      {name(member)}
    </Link>
  )
}

const COLUMNS: Column<Membership>[] = [
  { key: 'name', header: 'Name', cell: (m) => <NameLink member={m} />, className: 'whitespace-normal' },
  { key: 'role', header: 'Rolle', cell: (m) => m.role ?? dash },
  { key: 'from', header: 'seit', cell: (m) => formatDate(m.validFrom) },
  { key: 'to', header: 'bis', cell: (m) => (m.validTo ? formatDate(m.validTo) : dash) },
]

function MemberCard({ member }: { member: Membership }) {
  return (
    <div className="flex flex-col gap-1">
      <NameLink member={member} />
      <span className="text-sm text-muted-foreground">
        {[member.role, `seit ${formatDate(member.validFrom)}`, member.validTo && `bis ${formatDate(member.validTo)}`]
          .filter(Boolean)
          .join(' · ')}
      </span>
    </div>
  )
}
