import { Link, Outlet, useLocation } from 'react-router-dom'
import { useFiAccess } from '@/features/fi/access'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; isActive: (pathname: string) => boolean }

const SETTLEMENTS: NavItem = { to: '/fi', label: 'Abrechnungen', isActive: (p) => p === '/fi' || p.startsWith('/fi/abrechnung') }
const RUNS: NavItem = { to: '/fi/auszahlungen', label: 'Auszahlungsrunden', isActive: (p) => p.startsWith('/fi/auszahlungen') }
const CLIMBING: NavItem = { to: '/fi/kletterhalle', label: 'Punktekonto Kletterhalle', isActive: (p) => p.startsWith('/fi/kletterhalle') }

// FT11 (spec.md FI 6): Rahmen der Finanzen; Auszahlungsrunden und Kletterhalle nur mit „FI verwalten“.
export function FiLayout() {
  const { pathname } = useLocation()
  const { canManage } = useFiAccess()
  const nav = canManage ? [SETTLEMENTS, RUNS, CLIMBING] : [SETTLEMENTS]

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Finanzen" className="border-b pb-3">
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
