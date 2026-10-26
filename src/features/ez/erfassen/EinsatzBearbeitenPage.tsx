import { useLoaderData } from 'react-router-dom'
import type { EditContext } from '@/features/ez/erfassen/data'
import { EinsatzFormular } from '@/features/ez/erfassen/EinsatzFormular'
import { valuesFromDetail } from '@/features/ez/erfassen/values'
import { KIND_LABELS } from '@/features/ez/labels'

// T029 (US-EZ-12, -23): Einsatz korrigieren wie /ez/neu Schritt 2–3; Einsatzart und Gruppe nur angezeigt (R19);
// bei Einsätzen aus der Planungshilfe Kopf außer Bemerkung gesperrt und Personen aus der Planung fest (R25);
// abgerechnete Einsätze mit gesperrten Kopfdaten und Personen (R34, US-EZ-25).
export function EinsatzBearbeitenPage() {
  const { detail, names, ...context } = useLoaderData() as EditContext
  const e = detail.event
  return (
    <section className="flex flex-col gap-6">
      <h1 className="text-xl font-semibold">{KIND_LABELS[e.kind]} bearbeiten</h1>
      <EinsatzFormular
        context={context}
        initial={valuesFromDetail(detail)}
        eventId={e.id}
        initialNames={names}
        fromPlanning={e.from_planning}
        lockedPersonIds={detail.attendances.filter((a) => a.from_plan).map((a) => a.person_id)}
        settled={e.is_settled}
        settledPersonIds={detail.attendances.filter((a) => a.is_settled).map((a) => a.person_id)}
        remunerationName={e.remuneration_kind_name}
        groupLabel={detail.groups.map((g) => g.name).join(' + ')}
      />
    </section>
  )
}
