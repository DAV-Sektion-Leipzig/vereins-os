import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { formatDate, personName } from '@/lib/format'

// T073 (US-AD-25, R3, R40): Trefferliste der Dublettenprüfung; Aktionen je Modul als Props.
// Zeigt je Treffer nur Vorname, Nachname, Rufname, Geburtsjahr (falls geliefert) und „ausgeschieden seit“.
export type SimilarPerson = {
  person_id: string
  first_name: string
  last_name: string
  preferred_name: string | null
  birth_year: number | null
  volunteer_status: 'active' | 'dormant' | 'left' | null
  left_since: string | null
  is_visible: boolean
}

type Props = {
  open: boolean
  hits: SimilarPerson[]
  pending?: boolean
  onCreateAnyway: () => void
  onCancel: () => void
  /** Aktion je Treffer, z. B. „Vorhandene Person öffnen“ (nur bei sichtbaren Treffern) oder „Wieder aktivieren“ (EA). */
  hitAction?: (hit: SimilarPerson) => ReactNode
}

export function DublettenDialog({ open, hits, pending = false, onCreateAnyway, onCancel, hitAction }: Props) {
  return (
    <Dialog open={open} onOpenChange={(next) => !next && !pending && onCancel()}>
      <DialogContent showCloseButton={false} className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Ähnliche Personen gefunden</DialogTitle>
          <DialogDescription>
            {hits.length === 1 ? 'Eine ähnliche Person existiert bereits.' : `${hits.length} ähnliche Personen existieren bereits.`}{' '}
            Prüfe, ob es dieselbe Person ist, bevor du sie neu anlegst.
          </DialogDescription>
        </DialogHeader>

        <ul className="flex max-h-64 flex-col divide-y overflow-y-auto rounded-xl border">
          {hits.map((hit) => (
            <li key={hit.person_id} className="flex flex-col gap-2 px-3 py-2.5">
              <div className="flex flex-col gap-0.5">
                <span className="font-medium">{personName(hit)}</span>
                <span className="text-muted-foreground">
                  {hit.preferred_name && hit.preferred_name !== hit.first_name && <>Vorname {hit.first_name} · </>}
                  {hit.birth_year !== null && <>Jahrgang {hit.birth_year}</>}
                  {hit.birth_year !== null && hit.left_since && ' · '}
                  {hit.left_since && <>ausgeschieden seit {formatDate(hit.left_since)}</>}
                  {hit.birth_year === null && !hit.left_since && !(hit.preferred_name && hit.preferred_name !== hit.first_name) && '–'}
                </span>
              </div>
              {hitAction && <div className="flex flex-wrap gap-2">{hitAction(hit)}</div>}
            </li>
          ))}
        </ul>

        <DialogFooter>
          <Button variant="outline" onClick={onCancel} disabled={pending}>
            Abbrechen
          </Button>
          <Button onClick={onCreateAnyway} disabled={pending}>
            {pending ? 'Wird angelegt …' : 'Trotzdem anlegen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
