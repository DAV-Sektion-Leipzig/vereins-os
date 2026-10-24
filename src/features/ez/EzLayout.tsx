import { Link, Outlet, useLocation } from 'react-router-dom'
import { useEzAccess } from '@/features/ez/access'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; isActive: (pathname: string) => boolean }

const EVENTS: NavItem = { to: '/ez', label: 'Einsätze', isActive: (p) => p === '/ez' || /^\/ez\/(?!kletterhalle)/.test(p) }
const CLIMBING: NavItem = { to: '/ez/kletterhalle', label: 'Kontrolle Kletterhalle', isActive: (p) => p.startsWith('/ez/kletterhalle') }

// T020 (US-EZ-14): Rahmen der Anwesenheitserfassung mit Navigation „Einsätze · Kontrolle Kletterhalle“ (spec.md 6);
// Kontrolle Kletterhalle nur mit EZ ≥ bearbeiten oder Admin. Der Loader (access.ts) prüft EZ ≥ lesen.
export function EzLayout() {
  const { pathname } = useLocation()
  const { canEdit, canReadAll } = useEzAccess()
  const nav = canEdit || canReadAll ? [EVENTS, CLIMBING] : [EVENTS]

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Anwesenheitserfassung" className="border-b pb-3">
        <ul className="flex flex-wrap gap-1">
          {nav.map((item) => {
            const active = item.isActive(pathname)
            return (
              <li key={item.to}>
                <Link
                  to={item.to}
                  aria-current={active ? 'page' : undefined}
                  className={cn(
                    'inline-flex h-8 items-center rounded-lg px-3 text-sm transition-colors outline-none focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-1 focus-visible:outline-ring focus-visible:outline-solid',
                    active ? 'bg-accent font-medium text-accent-foreground' : 'hover:bg-muted',
                  )}
                >
                  {item.label}
                </Link>
              </li>
            )
          })}
        </ul>
      </nav>
      <Outlet />
    </div>
  )
}
