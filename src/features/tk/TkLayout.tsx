import { Link, Outlet, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; isActive: (pathname: string) => boolean }

const NAV: NavItem[] = [
  { to: '/tk', label: 'Planungen', isActive: (p) => p === '/tk' || /^\/tk\/(?!auswertung)/.test(p) },
  { to: '/tk/auswertung', label: 'Auswertung', isActive: (p) => p.startsWith('/tk/auswertung') },
]

// T018: Rahmen der Planungshilfe mit Navigation „Planungen · Auswertung“ (spec.md TK 6); der Loader prüft TK ≥ lesen.
export function TkLayout() {
  const { pathname } = useLocation()
  return (
    <div className="flex flex-col gap-6">
      <nav aria-label="Planungshilfe Touren und Kurse" className="border-b pb-3">
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
