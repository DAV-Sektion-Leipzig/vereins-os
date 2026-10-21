import { LogOutIcon } from 'lucide-react'
import { Link, useMatches, useNavigate } from 'react-router-dom'
import logoUrl from '@/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import type { Me } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type RouteHandle = {
  moduleName?: string
}

function useModuleName(): string | undefined {
  const matches = useMatches()
  for (let i = matches.length - 1; i >= 0; i--) {
    const handle = matches[i].handle as RouteHandle | undefined
    if (handle?.moduleName) return handle.moduleName
  }
  return undefined
}

export function AppHeader({ me }: { me: Me | null }) {
  const navigate = useNavigate()
  const moduleName = useModuleName()

  async function signOut() {
    await supabase.auth.signOut()
    navigate('/login', { replace: true })
  }

  return (
    <header className="border-t-3 border-b border-t-brand-band bg-background">
      {/* Schutzzone des Logos (docs/marke.md, DESIGN.md): Höhe des Edelweiß, bei 38 px Logo 24 px zu Band, Unterkante, Rand und Trennlinie */}
      <div className="mx-auto flex max-w-5xl items-center gap-3 p-6">
        <div className="flex min-w-0 flex-1 items-center">
          <Link
            to="/"
            className="flex shrink-0 items-center rounded-md outline-none focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-ring focus-visible:outline-solid"
          >
            <img src={logoUrl} alt="DAV Sektion Leipzig" className="h-9.5 w-auto" />
            <span className="ml-6 h-7 w-px bg-border" aria-hidden="true" />
            {/* Mobil verdrängt der Modulname den Produktnamen, damit nichts abgeschnitten wird */}
            <span className={cn('ml-3 font-semibold', moduleName && 'hidden sm:inline')}>Vereins OS</span>
          </Link>
          {moduleName && (
            <span className="ml-3 truncate font-semibold sm:ml-2 sm:text-sm sm:font-normal sm:text-muted-foreground">
              <span className="hidden sm:inline">· </span>
              {moduleName}
            </span>
          )}
        </div>
        {/* Mobil Name über „Abmelden“, damit keine zweite Zeile in die Schutzzone rückt */}
        <div className="flex min-w-0 shrink-0 flex-col items-end sm:flex-row sm:items-center sm:gap-3">
          {me && (
            <span className="max-w-36 truncate text-sm text-muted-foreground sm:max-w-48">
              {me.first_name} {me.last_name}
            </span>
          )}
          {/* Text bündig mit dem Namen darüber; die Fläche der Schaltfläche ragt in den Innenabstand */}
          <Button variant="ghost" className="-mr-2.5" onClick={signOut}>
            <LogOutIcon data-icon="inline-start" />
            Abmelden
          </Button>
        </div>
      </div>
    </header>
  )
}
