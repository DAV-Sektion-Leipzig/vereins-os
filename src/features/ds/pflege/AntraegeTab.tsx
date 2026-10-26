import { useState } from 'react'
import { useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import type { Request } from '@/features/ds/budget/data'
import { DecideDialog } from '@/features/ds/budget/dialogs'
import { euro, euroCents } from '@/features/ds/budget/ui'
import { dsRpc } from '@/features/ds/errors'
import type { PflegeData } from '@/features/ds/pflege/data'
import { formatDate, formatDateTime } from '@/lib/format'

type Decision = { request: Request; accept: boolean; scope?: 'booking' | 'account' }

const STATUS: Record<string, string> = {
  requested: 'beantragt',
  proposed: 'vorgeschlagen',
  confirmed: 'bestätigt',
  accepted: 'angenommen',
  rejected: 'abgelehnt',
  withdrawn: 'zurückgezogen',
  obsolete: 'gegenstandslos',
}

// US-DS-13, -15 (R15, R16): offene Umschichtungen bestätigen oder ablehnen (nicht den eigenen Antrag), Vorschläge
// annehmen (nur diese Buchung oder ganzes Konto) oder ablehnen; eigene offene Anträge zurückziehen.
export function AntraegeTab({ data }: { data: PflegeData }) {
  const [decision, setDecision] = useState<Decision | null>(null)
  const revalidator = useRevalidator()
  const open = data.requests.filter((r) => r.status === 'requested' || r.status === 'proposed')
  const done = data.requests.filter((r) => !open.includes(r))

  async function withdraw(r: Request) {
    const res = await dsRpc(r.request_type === 'reallocation' ? 'fi_budget_realloc_withdraw' : 'fi_budget_proposal_withdraw', { p_id: r.id })
    if (res.error) return toast.error(res.error.text)
    toast.success('Zurückgezogen.')
    revalidator.revalidate()
  }

  return (
    <div className="flex flex-col gap-5">
      {open.length === 0 ? (
        <p className="text-sm text-muted-foreground">Keine offenen Umschichtungen oder Vorschläge.</p>
      ) : (
        <ul className="flex flex-col gap-2">
          {open.map((r) => (
            <li key={r.id} className="flex flex-col gap-2 rounded-xl border px-3 py-2.5">
              <div className="flex flex-col gap-0.5 text-sm">
                <span className="font-medium">
                  {r.request_type === 'reallocation' ? 'Umschichtung' : 'Umschlüsselung'}: {r.from_name ?? '–'} → {r.to_name}, {euroCents(r.amount)}
                </span>
                {r.request_type === 'proposal' && (
                  <span className="text-muted-foreground">
                    Buchung {r.booking_date ? formatDate(r.booking_date) : '–'} · {r.booking_text ?? '–'}
                  </span>
                )}
                <span>Grund: {r.reason}</span>
                <span className="text-xs text-muted-foreground">
                  {r.requested_by ?? '–'} · {formatDateTime(r.requested_at)}
                </span>
              </div>
              <div className="flex flex-wrap gap-2">
                {r.can_decide && r.request_type === 'reallocation' && (
                  <Button size="sm" onClick={() => setDecision({ request: r, accept: true })}>
                    Bestätigen
                  </Button>
                )}
                {r.can_decide && r.request_type === 'proposal' && (
                  <>
                    <Button size="sm" onClick={() => setDecision({ request: r, accept: true, scope: 'booking' })}>
                      Annehmen (diese Buchung)
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => setDecision({ request: r, accept: true, scope: 'account' })}>
                      Annehmen (ganzes Konto)
                    </Button>
                  </>
                )}
                {r.can_decide && (
                  <Button size="sm" variant="outline" onClick={() => setDecision({ request: r, accept: false })}>
                    Ablehnen
                  </Button>
                )}
                {r.is_mine && (
                  <Button size="sm" variant="ghost" onClick={() => withdraw(r)}>
                    Zurückziehen
                  </Button>
                )}
                {r.is_mine && r.request_type === 'reallocation' && (
                  <span className="self-center text-xs text-muted-foreground">Deinen eigenen Antrag bestätigt eine andere Person mit Budgetpflege.</span>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}

      {done.length > 0 && (
        <section aria-labelledby="done-heading" className="flex flex-col gap-2">
          <h3 id="done-heading" className="font-medium">
            Eigene, bereits entschieden
          </h3>
          <ul className="flex flex-col divide-y rounded-xl border text-sm">
            {done.map((r) => (
              <li key={r.id} className="flex flex-wrap gap-x-3 px-3 py-2">
                <span>
                  {r.from_name ?? '–'} → {r.to_name}, {euro(r.amount)}
                </span>
                <span className="text-muted-foreground">
                  {STATUS[r.status] ?? r.status}
                  {r.decision_reason ? ` · ${r.decision_reason}` : ''}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {decision && (
        <DecideDialog
          title={
            decision.request.request_type === 'reallocation'
              ? decision.accept
                ? 'Umschichtung bestätigen'
                : 'Umschichtung ablehnen'
              : decision.accept
                ? 'Vorschlag annehmen'
                : 'Vorschlag ablehnen'
          }
          description={`${decision.request.from_name ?? '–'} → ${decision.request.to_name}, ${euroCents(decision.request.amount)}${
            decision.scope === 'account' ? '. Gilt für alle Buchungen auf dem Konto der Buchung.' : ''
          }`}
          fn={decision.request.request_type === 'reallocation' ? 'fi_budget_realloc_decide' : 'fi_budget_proposal_decide'}
          args={(reason) =>
            decision.request.request_type === 'reallocation'
              ? { p_id: decision.request.id, p_confirm: decision.accept, p_reason: reason }
              : { p_id: decision.request.id, p_accept: decision.accept, p_scope: decision.scope ?? 'booking', p_reason: reason }
          }
          reasonRequired={!decision.accept}
          submitLabel={decision.accept ? (decision.request.request_type === 'reallocation' ? 'Bestätigen' : 'Annehmen') : 'Ablehnen'}
          success={decision.accept ? 'Entschieden.' : 'Abgelehnt.'}
          onClose={() => setDecision(null)}
        />
      )}
    </div>
  )
}
