import { CircleAlertIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useAdAccess } from '@/features/ad/access'
import {
  CATEGORY_LABELS,
  READ_LEVEL_LABELS,
  RELATION_LABELS,
  type ListResult,
  type ListRow,
} from '@/features/ad/eigenschaftsarten/data'
import { MESSAGES } from '@/lib/errors'

// T080 (US-AD-12, US-AD-22): Liste der Eigenschaftsarten mit Kategorie, Lesestufe, Bezug, Anzahl Felder, sichtbar in.
// T051: `basePath` erlaubt dieselbe Seite unter /ea/eigenschaftsarten (US-EA-15).
export function EigenschaftsartenListe({ basePath = '/ad/eigenschaftsarten' }: { basePath?: string }) {
  const { items, modules, canEdit: canEditHere, failed } = useLoaderData() as ListResult
  const adAccess = useAdAccess()
  const canEdit = canEditHere ?? adAccess.canEdit
  const revalidator = useRevalidator()

  const moduleName = (code: string) => modules.find((m) => m.code === code)?.name ?? code

  const columns: Column<ListRow>[] = [
    {
      key: 'name',
      header: 'Name',
      cell: (t) => (
        <span className="flex flex-wrap items-center gap-2">
          <Link to={`${basePath}/${t.id}`} className="font-medium underline-offset-4 hover:underline">
            {t.name}
          </Link>
          {t.origin === 'system' && <Badge variant="outline">System</Badge>}
        </span>
      ),
      className: 'whitespace-normal',
    },
    { key: 'category', header: 'Kategorie', cell: (t) => CATEGORY_LABELS[t.category] },
    { key: 'read', header: 'Lesestufe', cell: (t) => READ_LEVEL_LABELS[t.read_level] },
    {
      key: 'relation',
      header: 'Bezug',
      cell: (t) => (t.relation_kind === 'none' ? <span className="text-muted-foreground">–</span> : RELATION_LABELS[t.relation_kind]),
    },
    { key: 'fields', header: 'Felder', cell: (t) => t.fieldCount, className: 'text-right tabular-nums', headerClassName: 'text-right' },
    { key: 'visible', header: 'Sichtbar in', cell: (t) => t.visible_in.map(moduleName).join(', '), className: 'whitespace-normal' },
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Eigenschaftsarten</h1>
        {canEdit && (
          <Button asChild>
            <Link to={`${basePath}/neu`}>
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
        <ResponsiveTable
          rows={items}
          rowKey={(t) => t.id}
          columns={columns}
          empty="Noch keine Eigenschaftsarten."
          caption="Eigenschaftsarten"
          card={(t) => (
            <div className="flex flex-col gap-1">
              <Link to={`${basePath}/${t.id}`} className="font-medium underline-offset-4 hover:underline">
                {t.name}
              </Link>
              <span className="text-sm text-muted-foreground">
                {CATEGORY_LABELS[t.category]} · {READ_LEVEL_LABELS[t.read_level]}
                {t.relation_kind !== 'none' && ` · Bezug ${RELATION_LABELS[t.relation_kind]}`}
              </span>
              <span className="text-sm text-muted-foreground">
                {t.fieldCount} {t.fieldCount === 1 ? 'Feld' : 'Felder'} · sichtbar in {t.visible_in.map(moduleName).join(', ')}
              </span>
            </div>
          )}
        />
      )}
    </section>
  )
}
