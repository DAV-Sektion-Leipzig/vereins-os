import { Link, Outlet, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; isActive: (pathname: string) => boolean }

const NAV: NavItem[] = [
  { to: '/gr', label: 'Gruppen', isActive: (p) => p === '/gr' || p.startsWith('/gr/gruppen') || p.startsWith('/gr/personen') },
  { to: '/gr/aufnahmen', label: 'Aufnahmen offen', isActive: (p) => p.startsWith('/gr/aufnahmen') },
]

// T024 (US-GR-02): Rahmen des Moduls Gruppen mit Navigation „Gruppen · Aufnahmen offen“ (spec.md 6);
// der Loader (access.ts) prüft GR ≥ lesen.
export function GrLayout() {
  const { pathname } = useLocation()

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Gruppen" className="border-b pb-3">
        <ul className="flex flex-wrap gap-1">
          {NAV.map((item) => {
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
