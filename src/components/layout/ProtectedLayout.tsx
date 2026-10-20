import { Outlet, useLoaderData } from 'react-router-dom'
import { AppHeader } from '@/components/layout/AppHeader'
import type { Me } from '@/lib/rights'

// Gemeinsamer Rahmen der geschützten Seiten; der Loader prüft die Sitzung und lädt die eigene Person.
export function ProtectedLayout() {
  const { me } = useLoaderData() as { me: Me | null }

  return (
    <div className="flex min-h-svh flex-col">
      <AppHeader me={me} />
      <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-6">
        <Outlet />
      </main>
    </div>
  )
}
