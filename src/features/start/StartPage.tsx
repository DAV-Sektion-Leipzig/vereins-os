import { Suspense } from 'react'
import { ChevronRightIcon, CircleAlertIcon, RotateCwIcon } from 'lucide-react'
import { Await, Link, useLoaderData, useRevalidator, useRouteLoaderData } from 'react-router-dom'
import welcomeUrl from '@/assets/willkommen.svg'
import { Button } from '@/components/ui/button'
import { MESSAGES } from '@/lib/errors'
import { LEVEL_LABELS, type Me } from '@/lib/rights'
import { MODULE_PATHS, type loadMyModules, type MyModulesResult } from '@/features/start/modules'
import { StartDashboard } from '@/features/start/StartDashboard'

// US-AD-05: Willkommensgrafik und Einstiege zu den Modulen, für die Rechte bestehen.
export function StartPage() {
  const { result } = useLoaderData() as ReturnType<typeof loadMyModules>
  const { me } = (useRouteLoaderData('protected') as { me: Me | null } | undefined) ?? { me: null }

  return (
    <div className="flex flex-col gap-8">
      {/* Mobil schmaler Streifen, damit die Module oben bleiben (Entscheidung PO 21.10.2026) */}
      <img src={welcomeUrl} alt="" className="h-18 w-full rounded-xl object-cover sm:h-44" />

      <h1 className="text-xl font-semibold text-balance">
        {me ? `Willkommen, ${me.first_name}` : 'Willkommen'}
      </h1>

      {/* US-DS-20: Dashboard über den Modulen, sobald DS freigegeben ist und Rechte bestehen */}
      <Suspense fallback={null}>
        <Await resolve={result}>{(r: MyModulesResult) => (r.modules.some((m) => m.code === 'DS') ? <StartDashboard /> : null)}</Await>
      </Suspense>

      <section aria-labelledby="modules-heading" className="flex flex-col gap-3">
        <h2 id="modules-heading" className="font-medium">
          Deine Module
        </h2>
        <Suspense fallback={<ModuleListLoading />}>
          <Await resolve={result}>{(r: MyModulesResult) => <ModuleList result={r} />}</Await>
        </Suspense>
      </section>
    </div>
  )
}

function ModuleListLoading() {
  return (
    <div role="status" className="flex items-center gap-3 rounded-xl border px-4 py-3 sm:w-[calc(50%-0.375rem)]">
      <span className="size-10 shrink-0 rounded-lg bg-muted" aria-hidden="true" />
      <span className="text-sm text-muted-foreground">Wird geladen …</span>
    </div>
  )
}

function ModuleList({ result }: { result: MyModulesResult }) {
  const revalidator = useRevalidator()

  if (result.failed) {
    return (
      <div className="flex flex-col items-start gap-3">
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
        <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
          <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
          {revalidator.state === 'loading' ? 'Wird geladen …' : 'Erneut laden'}
        </Button>
      </div>
    )
  }

  if (result.modules.length === 0) {
    return (
      <div className="flex flex-col gap-1 text-sm">
        <p>Für dich sind noch keine Module freigeschaltet.</p>
        <p className="text-muted-foreground">Wende dich an den Admin, wenn du Zugriff brauchst.</p>
      </div>
    )
  }

  return (
    <ul className="grid gap-3 sm:grid-cols-2">
      {result.modules.map((m) => (
        <li key={m.code}>
          <Link
            to={MODULE_PATHS[m.code]!}
            className="group flex items-center gap-3 rounded-xl border bg-card px-4 py-3 transition-colors outline-none hover:border-primary focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <span className="flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted text-sm font-semibold text-foreground">
              {m.code}
            </span>
            <span className="flex min-w-0 flex-1 flex-col">
              <span className="truncate font-medium">{m.name}</span>
              <span className="text-sm text-muted-foreground">{LEVEL_LABELS[m.level]}</span>
            </span>
            <ChevronRightIcon
              aria-hidden="true"
              className="size-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:text-primary"
            />
          </Link>
        </li>
      ))}
    </ul>
  )
}
