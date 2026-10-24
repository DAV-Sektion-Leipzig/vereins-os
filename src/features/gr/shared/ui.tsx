import type { ReactNode } from 'react'
import { CircleAlertIcon, RotateCwIcon, TriangleAlertIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MESSAGES } from '@/lib/errors'

// Gemeinsame Bausteine der Gruppen-Seiten (spec.md 6): Auswahlfeld, Hinweis-Badges, Ladefehler.
export const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:max-w-56 sm:text-sm'

/** Hinweis ohne Sperre (R2, R7, R17), z. B. „Kein Notfallkontakt hinterlegt.“ */
export function HintBadge({ children }: { children: ReactNode }) {
  return (
    <Badge className="bg-destructive/10 whitespace-normal text-destructive">
      <TriangleAlertIcon data-icon="inline-start" aria-hidden="true" />
      {children}
    </Badge>
  )
}

/** Ladefehler mit „Erneut laden“. */
export function LoadFailed({ text = MESSAGES.unexpected }: { text?: string }) {
  const revalidator = useRevalidator()
  return (
    <div className="flex flex-col items-start gap-3">
      <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
        <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
        {text}
      </p>
      <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
        <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
        {revalidator.state === 'loading' ? 'Wird geladen …' : 'Erneut laden'}
      </Button>
    </div>
  )
}

/** Fehlermeldung in Formularen und Dialogen. */
export function FormError({ text }: { text: string | null }) {
  if (!text) return null
  return (
    <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}
