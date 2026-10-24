import { useState } from 'react'
import { useLoaderData } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { todayIso } from '@/features/ez/dates'
import type { FormContext } from '@/features/ez/erfassen/data'
import { clearDraft, readDraft, type Draft } from '@/features/ez/erfassen/draft'
import { EinsatzFormular } from '@/features/ez/erfassen/EinsatzFormular'
import { emptyValues, type FormValues } from '@/features/ez/erfassen/values'
import { KIND_LABELS, KINDS, type EventKind } from '@/features/ez/labels'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { formatDate, formatTime } from '@/lib/format'

// T023 (US-EZ-01, -05, -06, -08, -09, -19, -20, -21): Schritt 1 Einsatzart als große Schaltflächen, Schritt 2–3 Formular
// mit Anwesenheit auf derselben Seite; Entwurf aus dem Browser fortsetzen oder verwerfen (US-EZ-18).
export function EinsatzNeuPage() {
  const context = useLoaderData() as FormContext
  const [draft, setDraft] = useState<Draft<FormValues> | null>(() => (context.userId ? readDraft<FormValues>(context.userId) : null))
  const [values, setValues] = useState<FormValues | null>(null)

  function choose(kind: EventKind) {
    setValues(emptyValues(kind, context, todayIso()))
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">{values ? `Neuer Einsatz: ${KIND_LABELS[values.kind]}` : 'Neuer Einsatz'}</h1>
        {values && (
          <Button variant="link" className="h-auto self-start p-0" onClick={() => setValues(null)}>
            Andere Einsatzart wählen
          </Button>
        )}
      </div>

      {values ? (
        <EinsatzFormular key={values.clientRequestId} context={context} initial={values} initialNames={{}} />
      ) : (
        <div className="grid grid-cols-1 gap-3 min-[375px]:grid-cols-2 sm:grid-cols-3">
          {KINDS.map((kind) => (
            <Button key={kind} variant="outline" onClick={() => choose(kind)} className="h-16 text-base whitespace-normal">
              {KIND_LABELS[kind]}
            </Button>
          ))}
        </div>
      )}

      {draft && !values && (
        <ConfirmDialog
          title="Nicht gespeicherte Eingabe"
          confirmLabel="Fortsetzen"
          pendingLabel="Fortsetzen"
          pending={false}
          error={null}
          onConfirm={() => {
            setValues(draft.values)
            setDraft(null)
          }}
          onClose={() => {
            clearDraft(context.userId)
            setDraft(null)
          }}
        >
          Es gibt eine nicht gespeicherte Eingabe vom {formatDate(draft.savedAt).slice(0, 6)} {formatTime(draft.savedAt)}. Fortsetzen?
        </ConfirmDialog>
      )}
    </section>
  )
}
