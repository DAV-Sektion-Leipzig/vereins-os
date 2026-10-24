import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { MembershipRow } from '@/features/gr/gruppen/detail'
import type { ContractRow, PersonCore } from '@/features/gr/personen/data'
import { contractPayload, EMPTY_CONTRACT, type ContractForm } from '@/features/gr/personen/fields'
import { VertragFelder } from '@/features/gr/personen/VertragFelder'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { todayIso } from '@/lib/format'

export type ContractAction =
  | { kind: 'cancel'; contract: ContractRow; membership: MembershipRow & { group_name: string } }
  | { kind: 'edit'; contract: ContractRow }
  | { kind: 'follow'; membership: MembershipRow & { group_name: string } }
  | { kind: 'end'; membership: MembershipRow & { group_name: string } }

const TITLES: Record<ContractAction['kind'], string> = {
  cancel: 'Vertrag kündigen',
  edit: 'Vertrag ändern',
  follow: 'Folgevertrag anlegen',
  end: '„Teilnahme bis“ ändern',
}

// T039 (US-GR-11, R8, R8a, R8b): kündigen (mit Rückfrage zur Teilnahme), ändern, Folgevertrag, „Teilnahme bis“
export function VertragDialog({
  action,
  holders,
  onClose,
  onDone,
}: {
  action: ContractAction
  holders: PersonCore[]
  onClose: () => void
  onDone: () => void
}) {
  const [cancelledOn, setCancelledOn] = useState(action.kind === 'cancel' ? (action.contract.cancelled_on ?? todayIso()) : todayIso())
  const [endsOn, setEndsOn] = useState(action.kind === 'cancel' ? (action.contract.ends_on ?? '') : '')
  const [endMembership, setEndMembership] = useState<boolean | null>(null)
  const [leftOn, setLeftOn] = useState(action.kind === 'end' ? (action.membership.left_on ?? todayIso()) : '')
  const [contract, setContract] = useState<ContractForm>(
    action.kind === 'edit'
      ? {
          holder_person_id: action.contract.holder_person_id,
          starts_on: action.contract.starts_on,
          account_holder: action.contract.account_holder,
          iban: action.contract.iban,
          mandate_reference: action.contract.mandate_reference,
          mandate_signed_on: action.contract.mandate_signed_on,
          purpose: action.contract.purpose,
          monthly_amount: String(action.contract.monthly_amount).replace('.', ','),
        }
      : EMPTY_CONTRACT,
  )
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    let result
    if (action.kind === 'cancel') {
      if (!cancelledOn || !endsOn) return setError(MESSAGES.grContractFieldsRequired)
      // R8b: Rückfrage, ob auch die Teilnahme endet
      if (endMembership === null) return setError('Bitte angeben, ob auch die Teilnahme an der Gruppe endet.')
      setPending(true)
      result = await grRpc('gr_cancel_contract', {
        p_contract: action.contract.id,
        p_cancelled_on: cancelledOn,
        p_ends_on: endsOn,
        p_end_membership: endMembership,
      })
    } else if (action.kind === 'edit') {
      setPending(true)
      const { starts_on: _ignored, ...data } = contractPayload(contract)
      result = await grRpc('gr_update_contract', { p_contract: action.contract.id, p_data: data })
    } else if (action.kind === 'follow') {
      setPending(true)
      result = await grRpc('gr_add_contract', { p_membership: action.membership.membership_id, p_contract: contractPayload(contract) })
    } else {
      setPending(true)
      result = await grRpc('gr_end_membership', { p_membership: action.membership.membership_id, p_left_on: leftOn || null })
    }
    setPending(false)
    if (result.error !== null) return setError(result.error)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{TITLES[action.kind]}</DialogTitle>
          {'membership' in action && <DialogDescription>{action.membership.group_name}</DialogDescription>}
        </DialogHeader>
        <form id="gr-contract-form" onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          {action.kind === 'cancel' && (
            <>
              <div className="grid gap-3 sm:grid-cols-2">
                <div className="flex flex-col gap-2">
                  <Label htmlFor="gr-cancelled-on">Kündigung eingegangen am</Label>
                  <Input id="gr-cancelled-on" type="date" value={cancelledOn} onChange={(e) => setCancelledOn(e.target.value)} />
                </div>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="gr-ends-on">Vertragsende (letzter Tag)</Label>
                  <Input id="gr-ends-on" type="date" value={endsOn} onChange={(e) => setEndsOn(e.target.value)} />
                </div>
              </div>
              <fieldset className="flex flex-col gap-2">
                <legend className="mb-2 text-sm font-medium">Endet auch die Teilnahme an der Gruppe?</legend>
                <label className="flex items-center gap-2 text-sm">
                  <input type="radio" name="gr-end-membership" checked={endMembership === true} onChange={() => setEndMembership(true)} className="size-4 accent-primary" />
                  Ja, „Teilnahme bis“ = Vertragsende
                </label>
                <label className="flex items-center gap-2 text-sm">
                  <input type="radio" name="gr-end-membership" checked={endMembership === false} onChange={() => setEndMembership(false)} className="size-4 accent-primary" />
                  Nein, Teilnahme bleibt unverändert
                </label>
              </fieldset>
            </>
          )}
          {(action.kind === 'edit' || action.kind === 'follow') && (
            <VertragFelder value={contract} onChange={setContract} holders={holders} withStart={action.kind === 'follow'} />
          )}
          {action.kind === 'end' && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="gr-left-on">Teilnahme bis</Label>
              <Input id="gr-left-on" type="date" value={leftOn} onChange={(e) => setLeftOn(e.target.value)} className="sm:w-44" />
            </div>
          )}
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-contract-form" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
