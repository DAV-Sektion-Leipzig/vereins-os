import { Link, Outlet, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { useEaAccess } from './access'

type NavItem = { to: string; label: string; manageOnly: boolean }

const NAV: NavItem[] = [
  { to: '/ea/aktive', label: 'Aktive', manageOnly: false },
  { to: '/ea/ablauf', label: 'Ablauf', manageOnly: false },
  { to: '/ea/gremien', label: 'Gremien', manageOnly: true },
  { to: '/ea/eigenschaftsarten', label: 'Eigenschaftsarten', manageOnly: true },
  { to: '/ea/qualifikationsarten', label: 'Qualifikationsarten', manageOnly: true },
  { to: '/ea/stammdaten', label: 'Referate und Gremien', manageOnly: true },
]

// T032: Rahmen des Ehrenamtsmanagements mit Navigation nach A6; der Loader (access.ts) prüft EA ≥ lesen.
export function EaLayout() {
  const { pathname } = useLocation()
  const { canManage } = useEaAccess()
  const items = NAV.filter((item) => canManage || !item.manageOnly)

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Ehrenamtsmanagement" className="border-b pb-3">
        <ul className="flex flex-wrap gap-1">
          {items.map((item) => {
            const active = pathname === item.to || pathname.startsWith(`${item.to}/`)
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
