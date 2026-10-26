import { Link, Outlet, useLocation } from 'react-router-dom'
import { useDsAccess } from '@/features/ds/access'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; isActive: (pathname: string) => boolean }

const DASHBOARD: NavItem = {
  to: '/dashboard',
  label: 'Dashboard',
  isActive: (p) => p === '/dashboard' || p.startsWith('/dashboard/budget/posten'),
}
const VEREIN: NavItem = { to: '/dashboard/verein', label: 'Verein', isActive: (p) => p.startsWith('/dashboard/verein') }
const PFLEGE: NavItem = { to: '/dashboard/budget/pflege', label: 'Budgetpflege', isActive: (p) => p.startsWith('/dashboard/budget/pflege') }

// Rahmen des Dashboards (spec.md DS v0.2 Abschnitt 6); Budgetpflege nur mit dem Kennzeichen „darf Budget pflegen“.
export function DsLayout() {
  const { pathname } = useLocation()
  const { maintain } = useDsAccess()
  const nav = maintain ? [DASHBOARD, VEREIN, PFLEGE] : [DASHBOARD, VEREIN]

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Dashboard" className="border-b pb-3 print:hidden">
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
