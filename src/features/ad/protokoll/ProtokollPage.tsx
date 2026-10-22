import { CircleAlertIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { ACTION_LABELS, type AuditResult, type AuditRow } from '@/features/ad/protokoll/data'
import { MESSAGES } from '@/lib/errors'
import { formatDateTime } from '@/lib/format'

// T101 (US-AD-14): Protokoll – Zeitpunkt, ausgeführt von, betroffene Person, Aktion, Details; neueste zuerst.
export function ProtokollPage() {
  const { rows, total, page, failed } = useLoaderData() as AuditResult
  const revalidator = useRevalidator()

  const columns: Column<AuditRow>[] = [
    { key: 'time', header: 'Zeitpunkt', cell: (r) => formatDateTime(r.occurred_at), className: 'whitespace-nowrap tabular-nums' },
    { key: 'actor', header: 'Ausgeführt von', cell: (r) => r.actor_name ?? <span className="text-muted-foreground">–</span> },
    {
      key: 'subject',
      header: 'Betroffene Person',
      cell: (r) => (
        <Link to={`/ad/personen/${r.subject_person_id}`} className="underline-offset-4 hover:underline">
          {r.subject_name}
        </Link>
      ),
    },
    { key: 'action', header: 'Aktion', cell: (r) => ACTION_LABELS[r.action] ?? r.action },
    { key: 'details', header: 'Details', cell: (r) => r.details ?? <span className="text-muted-foreground">–</span>, className: 'whitespace-normal' },
  ]

  return (
    <section className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Protokoll</h1>
      <p className="text-sm text-muted-foreground">
        Einladungen, Rechtevergaben, Sperren und Anmeldungen des Notfall-Admins; Aufbewahrung 5 Jahre.
      </p>

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
            rowKey={(r) => String(r.id)}
            columns={columns}
            empty="Noch keine Einträge."
            caption="Protokoll"
            card={(r) => (
              <div className="flex flex-col gap-1 text-sm">
                <span className="font-medium">{ACTION_LABELS[r.action] ?? r.action}</span>
                <span className="text-muted-foreground tabular-nums">{formatDateTime(r.occurred_at)}</span>
                <span>
                  <Link to={`/ad/personen/${r.subject_person_id}`} className="underline-offset-4 hover:underline">
                    {r.subject_name}
                  </Link>
                  {r.actor_name && <span className="text-muted-foreground"> · von {r.actor_name}</span>}
                </span>
                {r.details && <span className="text-muted-foreground">{r.details}</span>}
              </div>
            )}
          />
          <Pagination page={page} total={total} href={(p) => (p > 1 ? `/ad/protokoll?seite=${p}` : '/ad/protokoll')} label="Einträge" />
        </>
      )}
    </section>
  )
}
