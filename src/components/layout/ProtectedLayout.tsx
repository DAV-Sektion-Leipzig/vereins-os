import { Outlet, useLoaderData, useNavigation } from 'react-router-dom'
import { AppHeader } from '@/components/layout/AppHeader'
import type { Me } from '@/lib/rights'
import { cn } from '@/lib/utils'

// Gemeinsamer Rahmen der geschützten Seiten; der Loader prüft die Sitzung und lädt die eigene Person.
export function ProtectedLayout() {
  const { me } = useLoaderData() as { me: Me | null }
  const navigation = useNavigation()
  const loading = navigation.state === 'loading'

  return (
    <div className="flex min-h-svh flex-col">
      <AppHeader me={me} />
      {/* Beim Seitenwechsel bleibt der alte Inhalt gedämpft stehen, bis die neuen Daten da sind */}
      <main
        aria-busy={loading}
        className={cn('mx-auto w-full max-w-5xl flex-1 px-6 py-6 transition-opacity', loading && 'opacity-60')}
      >
        {loading && (
          <p role="status" className="sr-only">
            Wird geladen …
          </p>
        )}
        <Outlet />
      </main>
    </div>
  )
}
