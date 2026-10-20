import { LogOutIcon } from 'lucide-react'
import { Link, useMatches, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
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
    <header className="border-b bg-background">
      <div className="mx-auto flex max-w-5xl items-center gap-3 px-4 py-2">
        <div className="flex min-w-0 flex-1 items-baseline gap-2">
          <Link to="/" className="shrink-0 font-semibold">
            Vereins OS
          </Link>
          {moduleName && (
            <span className="truncate text-sm text-muted-foreground">· {moduleName}</span>
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
