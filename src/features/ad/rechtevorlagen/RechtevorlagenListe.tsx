import { CircleAlertIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useAdAccess } from '@/features/ad/access'
import { personCountLabel, type ListResult } from '@/features/ad/rechtevorlagen/data'
import { MESSAGES } from '@/lib/errors'

// T033 (US-AD-10): Liste der Rechtevorlagen; ab 640 px Tabelle, darunter Karten.
export function RechtevorlagenListe() {
  const { templates, failed } = useLoaderData() as ListResult
  const { canEdit } = useAdAccess()
  const revalidator = useRevalidator()

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Rechtevorlagen</h1>
        {canEdit && (
          <Button asChild>
            <Link to="/ad/rechtevorlagen/neu">
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Neu
            </Link>
          </Button>
        )}
      </div>

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
          <div className="hidden rounded-xl border sm:block">
            <Table>
              <TableHeader>
                <TableRow className="bg-muted hover:bg-muted">
                  <TableHead className="pl-4">Name</TableHead>
                  <TableHead>Beschreibung</TableHead>
                  <TableHead className="text-right">Personen</TableHead>
                  <TableHead className="w-0 pr-4">
                    <span className="sr-only">Aktion</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {templates.map((t) => (
                  <TableRow key={t.id} className="hover:bg-transparent">
                    <TableCell className="pl-4 font-medium">{t.name}</TableCell>
                    <TableCell className="whitespace-normal text-muted-foreground">{t.description}</TableCell>
                    <TableCell className="text-right">{t.personCount}</TableCell>
                    <TableCell className="pr-4">
                      <Button variant="outline" asChild>
                        <Link to={`/ad/rechtevorlagen/${t.id}`} aria-label={`${t.name} öffnen`}>
                          Öffnen
                        </Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>

          <ul className="flex flex-col gap-3 sm:hidden">
            {templates.map((t) => (
              <li key={t.id} className="flex flex-col gap-3 rounded-xl border p-4">
                <div className="flex flex-col gap-1">
                  <span className="font-medium">{t.name}</span>
                  {t.description && <span className="text-sm text-muted-foreground">{t.description}</span>}
                  <span className="text-sm text-muted-foreground tabular-nums">{personCountLabel(t.personCount)}</span>
                </div>
                <Button variant="outline" asChild className="self-start">
                  <Link to={`/ad/rechtevorlagen/${t.id}`} aria-label={`${t.name} öffnen`}>
                    Öffnen
                  </Link>
                </Button>
              </li>
            ))}
          </ul>
        </>
      )}
    </section>
  )
}
