import { ChevronLeftIcon, ChevronRightIcon } from 'lucide-react'
import { Link } from 'react-router-dom'
import { buttonVariants } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// T070: Seitenweise Anzeige, 50 je Seite (spec.md AD Abschnitt 6, Personenübersicht [ANNAHME v0.7]).
export const PAGE_SIZE = 50

type Props = {
  page: number
  total: number
  pageSize?: number
  /** Ziel je Seite, z. B. mit erhaltenen Suchparametern. */
  href: (page: number) => string
  /** Bezeichnung der Einträge, z. B. „Personen“. */
  label: string
}

export function Pagination({ page, total, pageSize = PAGE_SIZE, href, label }: Props) {
  const pages = Math.max(1, Math.ceil(total / pageSize))
  if (total <= pageSize) return null

  const from = (page - 1) * pageSize + 1
  const to = Math.min(page * pageSize, total)

  return (
    <nav aria-label={`Seiten der ${label}`} className="flex flex-wrap items-center justify-between gap-3">
      <p className="text-sm text-muted-foreground tabular-nums">
        {from}–{to} von {total} {label}
      </p>
      <div className="flex gap-2">
        <PageLink to={page > 1 ? href(page - 1) : null} label="Zurück">
          <ChevronLeftIcon data-icon="inline-start" aria-hidden="true" />
          Zurück
        </PageLink>
        <PageLink to={page < pages ? href(page + 1) : null} label="Weiter">
          Weiter
          <ChevronRightIcon data-icon="inline-end" aria-hidden="true" />
        </PageLink>
      </div>
    </nav>
  )
}

function PageLink({ to, label, children }: { to: string | null; label: string; children: React.ReactNode }) {
  const className = buttonVariants({ variant: 'outline' })
  if (!to) {
    return (
      <span aria-disabled="true" aria-label={label} className={cn(className, 'pointer-events-none opacity-50')}>
        {children}
      </span>
    )
  }
  return (
    <Link to={to} className={className}>
      {children}
    </Link>
  )
}
