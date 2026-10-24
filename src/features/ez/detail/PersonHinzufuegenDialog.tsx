import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { ROLE_LABELS, type EventKind, type Role } from '@/features/ez/labels'
import { AktivenSuche, type ActivePerson } from '@/features/ez/shared/AktivenSuche'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { personName } from '@/lib/format'

type Props = {
  kind: EventKind
  excludeIds: string[]
  onClose: () => void
  /** Gibt eine Fehlermeldung zurück oder null bei Erfolg. */
  onAdd: (personId: string, role: Role) => Promise<string | null>
}

// T029 (US-EZ-10): Spontane Person vor Ort ergänzen (Suche „Aktive“, R20); Rolle Helfer:in beim Arbeitseinsatz,
// Trainer:in bei Kurs und Tour vorbelegt und änderbar; Stand „anwesend“.
export function PersonHinzufuegenDialog({ kind, excludeIds, onClose, onAdd }: Props) {
  const [person, setPerson] = useState<ActivePerson | null>(null)
  const [role, setRole] = useState<Role>(kind === 'work_assignment' ? 'helper' : 'trainer')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function add() {
    if (!person) return
    setPending(true)
    const message = await onAdd(person.id, role)
    setPending(false)
    if (message) setError(message)
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Person hinzufügen</DialogTitle>
          <DialogDescription>Die Person wird als anwesend eingetragen.</DialogDescription>
        </DialogHeader>
        {person ? (
          <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between gap-3 rounded-xl border px-3 py-2.5">
              <span className="font-medium">{personName(person)}</span>
              <Button variant="ghost" size="sm" onClick={() => setPerson(null)} disabled={pending}>
                Ändern
              </Button>
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="ez-add-role">Rolle</Label>
              <select id="ez-add-role" value={role} onChange={(e) => setRole(e.target.value as Role)} className={selectClassName}>
                {(['trainer', 'helper'] as Role[]).map((r) => (
                  <option key={r} value={r}>
                    {ROLE_LABELS[r]}
                  </option>
                ))}
              </select>
            </div>
          </div>
        ) : (
          <AktivenSuche label="Person suchen" excludeIds={excludeIds} onSelect={setPerson} />
        )}
        <FormError text={error} />
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button onClick={add} disabled={!person || pending}>
            {pending ? 'Wird eingetragen …' : 'Hinzufügen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
