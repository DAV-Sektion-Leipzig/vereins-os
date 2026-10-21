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
      <div className="mx-auto flex max-w-5xl items-center gap-3 px-4 py-2">
        <div className="flex min-w-0 flex-1 items-center">
          {/* Logo unverändert (docs/marke.md); „Vereins OS“ steht getrennt davon, durch Abstand und Trennlinie */}
          <Link to="/" className="flex shrink-0 items-center gap-3 rounded-md sm:gap-4">
            <img src={logoUrl} alt="DAV Sektion Leipzig" className="h-11 w-auto sm:h-12" />
            <span className="h-7 w-px bg-border" aria-hidden="true" />
            {/* Mobil verdrängt der Modulname den Produktnamen, damit nichts abgeschnitten wird */}
            <span className={cn('font-semibold', moduleName && 'hidden sm:inline')}>Vereins OS</span>
          </Link>
          {moduleName && (
            <span className="ml-3 truncate font-semibold sm:ml-2 sm:text-sm sm:font-normal sm:text-muted-foreground">
              <span className="hidden sm:inline">· </span>
              {moduleName}
            </span>
          )}
        </div>
        {me && (
          <span className="hidden max-w-48 truncate text-sm text-muted-foreground sm:inline">
            {me.first_name} {me.last_name}
          </span>
        )}
        <Button variant="ghost" size="sm" onClick={signOut}>
          <LogOutIcon data-icon="inline-start" />
          Abmelden
        </Button>
      </div>
      {me && (
        <div className="mx-auto max-w-5xl truncate px-4 pb-2 text-sm text-muted-foreground sm:hidden">
          {me.first_name} {me.last_name}
        </div>
      )}
    </header>
  )
}
