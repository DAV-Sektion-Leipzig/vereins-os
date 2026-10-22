import { Link, Outlet, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'

const NAV = [
  { to: '/ad', label: 'Personen', match: (p: string) => p === '/ad' || p.startsWith('/ad/personen') },
  { to: '/ad/rechtevorlagen', label: 'Rechtevorlagen', match: (p: string) => p.startsWith('/ad/rechtevorlagen') },
  { to: '/ad/eigenschaftsarten', label: 'Eigenschaftsarten', match: (p: string) => p.startsWith('/ad/eigenschaftsarten') },
  { to: '/ad/qualifikationsarten', label: 'Qualifikationsarten', match: (p: string) => p.startsWith('/ad/qualifikationsarten') },
  { to: '/ad/protokoll', label: 'Protokoll', match: (p: string) => p.startsWith('/ad/protokoll') },
]

// T067: Rahmen der Administration mit Navigation (contracts/routes.md); der Loader (access.ts) prüft AD ≥ lesen.
export function AdLayout() {
  const { pathname } = useLocation()

  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Administration" className="border-b pb-3">
        <ul className="flex flex-wrap gap-1">
          {NAV.map((item) => {
            const active = item.match(pathname)
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
