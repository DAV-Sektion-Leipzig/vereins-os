import { Link, Outlet, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string }

const NAV: NavItem[] = [
  { to: '/schnittstellen', label: 'Anbindungen' },
  { to: '/schnittstellen/vorlagen', label: 'Vorlagen' },
  { to: '/schnittstellen/postausgang', label: 'Postausgang' },
  { to: '/schnittstellen/protokoll', label: 'Protokoll' },
]

// Rahmen der Seite „Schnittstellen“ mit vier Reitern (spec.md SC v0.2 Abschnitt 6).
export function ScLayout() {
  const { pathname } = useLocation()

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Schnittstellen" className="border-b pb-3">
        <ul className="flex flex-wrap gap-1">
          {NAV.map((item) => {
            const active = item.to === '/schnittstellen' ? pathname === item.to : pathname.startsWith(item.to)
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
