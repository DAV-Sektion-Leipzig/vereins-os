import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { PersonCore } from '@/features/gr/personen/data'
import { selectClassName } from '@/features/gr/shared/ui'
import { personName } from '@/lib/format'
import type { ContractForm } from '@/features/gr/personen/fields'

/** Vertragsangaben (GR spec.md 2.1, R4–R6, R27); Vertragsinhaber:in aus den Erziehungsberechtigten oder die Person selbst. */
export function VertragFelder({
  value,
  onChange,
  holders,
  withStart = true,
}: {
  value: ContractForm
  onChange: (next: ContractForm) => void
  holders: PersonCore[]
  withStart?: boolean
}) {
  const set = (patch: Partial<ContractForm>) => onChange({ ...value, ...patch })
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-holder">Vertragsinhaber:in</Label>
        <select
          id="gr-contract-holder"
          value={value.holder_person_id}
          onChange={(e) => {
            const holder = holders.find((h) => h.id === e.target.value)
            set({ holder_person_id: e.target.value, account_holder: value.account_holder || (holder ? personName(holder) : '') })
          }}
          className={selectClassName}
        >
          <option value="">bitte wählen</option>
          {holders.map((h) => (
            <option key={h.id} value={h.id}>
              {personName(h)}
            </option>
          ))}
        </select>
      </div>
      {withStart && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="gr-contract-start">Vertragsbeginn</Label>
          <Input id="gr-contract-start" type="date" value={value.starts_on} onChange={(e) => set({ starts_on: e.target.value })} className="sm:w-44" />
        </div>
      )}
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-account">Kontoinhaber:in</Label>
        <Input id="gr-contract-account" value={value.account_holder} maxLength={70} onChange={(e) => set({ account_holder: e.target.value })} />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-iban">IBAN</Label>
        <Input id="gr-contract-iban" value={value.iban} onChange={(e) => set({ iban: e.target.value })} autoComplete="off" />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-mandate">Mandatsreferenz</Label>
        <Input id="gr-contract-mandate" value={value.mandate_reference} maxLength={35} onChange={(e) => set({ mandate_reference: e.target.value })} />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-signed">Unterschrift des Mandats am</Label>
        <Input id="gr-contract-signed" type="date" value={value.mandate_signed_on} onChange={(e) => set({ mandate_signed_on: e.target.value })} className="sm:w-44" />
      </div>
      <div className="flex flex-col gap-2 sm:col-span-2">
        <Label htmlFor="gr-contract-purpose">Verwendungszweck</Label>
        <Input id="gr-contract-purpose" value={value.purpose} maxLength={140} onChange={(e) => set({ purpose: e.target.value })} />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-contract-amount">Betrag je Monat (EUR)</Label>
        <Input
          id="gr-contract-amount"
          inputMode="decimal"
          value={value.monthly_amount}
          onChange={(e) => set({ monthly_amount: e.target.value })}
          className="sm:w-32"
        />
      </div>
    </div>
  )
}
