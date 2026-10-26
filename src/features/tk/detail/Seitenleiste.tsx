import { CheckIcon, CircleAlertIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import type { CalcResult } from '@/features/tk/calc'
import { formatKg, formatMoney, missingLabel, STEPS, stepOf, WARNING_LABELS } from '@/features/tk/labels'
import type { PlanType, Rates, Results } from '@/features/tk/types'
import { cn } from '@/lib/utils'

type Props = {
  planType: PlanType
  calc: CalcResult
  results: Results | null
  rates: Rates
  minParticipants: number | null
  onStep: (n: number) => void
}

const CO2_LABELS = { missing: 'Anreise fehlt', mostly_pt: 'überwiegend ÖPV', mixed: 'gemischt', mostly_car_flight: 'überwiegend PKW/Flug' }

function Pill({ ok, children }: { ok: boolean; children: string }) {
  return <Badge className={cn(ok ? 'bg-primary/10 text-primary' : 'bg-destructive/10 text-destructive')}>{children}</Badge>
}

// Seitenleiste (spec.md TK 6, Prototyp 6.4): Beitrag und CO2-Bilanz live (calc.ts), Fortschritt und Hinweise aus dem
// letzten Ergebnis der Datenbank (maßgeblich, R1).
export function Seitenleiste({ planType, calc, results, rates, minParticipants, onStep }: Props) {
  const missing = results?.missing ?? []
  const warnings = results?.warnings ?? []
  const beitrag = planType === 'community_tour'
    ? 'ohne Zahlung'
    : calc.is_free
      ? 'Sektion trägt Kosten'
      : !minParticipants
        ? 'Mindestanzahl fehlt'
        : (calc.result_min ?? -1) >= -0.005
          ? 'kostendeckend'
          : 'nicht gedeckt'
  const beitragOk = beitrag === 'kostendeckend' || beitrag === 'ohne Zahlung'
  const rateLabel = (k: string) => rates[k]?.label
  return (
    <aside className="flex flex-col gap-6 rounded-xl border p-4 lg:sticky lg:top-4">
      <section className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-2">
          <h2 className="font-semibold">Teilnahmebeitrag</h2>
          <Pill ok={beitragOk}>{beitrag}</Pill>
        </div>
        {!calc.is_free && planType !== 'community_tour' && (
          <p className="text-2xl font-semibold tabular-nums">{formatMoney(calc.price_member_effective, true)}</p>
        )}
        <dl className="grid grid-cols-[1fr_auto] gap-x-3 gap-y-1 text-sm">
          <dt className="text-muted-foreground">Gesamtkosten</dt>
          <dd className="text-right tabular-nums">{formatMoney(calc.total_costs)}</dd>
          {!calc.is_free && (
            <>
              <dt className="text-muted-foreground">Kostendeckend ab</dt>
              <dd className="text-right tabular-nums">{calc.break_even !== null ? `${calc.break_even} TN` : '–'}</dd>
              <dt className="text-muted-foreground">Ergebnis bei Min. / Max.</dt>
              <dd className="text-right tabular-nums">
                {formatMoney(calc.result_min, true)} / {formatMoney(calc.result_max, true)}
              </dd>
            </>
          )}
          {calc.section_bears > 0 && (
            <>
              <dt className="text-muted-foreground">Sektion trägt</dt>
              <dd className="text-right tabular-nums">{formatMoney(calc.section_bears)}</dd>
            </>
          )}
        </dl>
        {!calc.is_free && (calc.result_max ?? 0) > 0 && (
          <p className="text-xs text-muted-foreground">
            Bei voller Belegung bleiben {formatMoney(calc.result_max, true)} übrig. Der Überschuss bleibt bei der Sektion und gleicht
            Touren ohne Überschuss aus.
          </p>
        )}
      </section>

      <section className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-2">
          <h2 className="font-semibold">CO2-Bilanz</h2>
          <Pill ok={calc.co2_status === 'mostly_pt'}>{CO2_LABELS[calc.co2_status]}</Pill>
        </div>
        <dl className="grid grid-cols-[1fr_auto] gap-x-3 gap-y-1 text-sm">
          <dt className="text-muted-foreground">Tour (ohne DAV-Hütten)</dt>
          <dd className="text-right tabular-nums">{formatKg(calc.co2_tour_kg)}</dd>
          <dt className="text-muted-foreground">je Person</dt>
          <dd className="text-right tabular-nums">{formatKg(calc.co2_per_person_kg)}</dd>
          <dt className="text-muted-foreground">je Person und Tag</dt>
          <dd className="text-right tabular-nums">{formatKg(calc.co2_per_person_day_kg)}</dd>
          <dt className="text-muted-foreground">Klimaschutzbudget</dt>
          <dd className="text-right tabular-nums">{formatMoney(calc.climate_budget_eur)}</dd>
        </dl>
      </section>

      <section className="flex flex-col gap-2">
        <h2 className="font-semibold">
          Fortschritt{results ? ` · ${missing.length === 0 ? 'alles ausgefüllt' : `${missing.length} offen`}` : ''}
        </h2>
        <ul className="flex flex-col gap-1 text-sm">
          {STEPS.map((s) => {
            const open = missing.filter((m) => stepOf(m) === s.n)
            return (
              <li key={s.n}>
                <button type="button" onClick={() => onStep(s.n)} title={open.map((m) => missingLabel(m, rateLabel)).join(', ')}
                  className="flex w-full items-center justify-between gap-2 rounded-md px-2 py-1 text-left hover:bg-muted">
                  <span>
                    {s.n}. {s.title}
                  </span>
                  {open.length === 0 ? (
                    <CheckIcon aria-label="fertig" className="size-4 text-primary" />
                  ) : (
                    <span className="text-xs text-destructive">{open.length} offen</span>
                  )}
                </button>
              </li>
            )
          })}
        </ul>
      </section>

      {warnings.length > 0 && (
        <section className="flex flex-col gap-2">
          <h2 className="font-semibold">Hinweise</h2>
          <ul className="flex flex-col gap-2 text-sm">
            {warnings.map((w) => (
              <li key={w} className="flex gap-2">
                <CircleAlertIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-destructive" />
                {WARNING_LABELS[w] ?? w}
              </li>
            ))}
          </ul>
        </section>
      )}
    </aside>
  )
}
