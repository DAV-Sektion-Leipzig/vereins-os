import { useEffect, useState } from 'react'
import { loadHints, type StatusHint } from '@/features/sc/data'
import { StatusHints } from '@/features/sc/ui'

// US-SC-13: Hinweis auf der Startseite für Nutzer mit SC ≥ lesen (gestört, abgelaufen, Key läuft ab, fehlgeschlagen,
// Tageslimit). Ohne Hinweise erscheint nichts.
export function StartHinweise() {
  const [hints, setHints] = useState<StatusHint[]>([])

  useEffect(() => {
    let active = true
    loadHints().then((h) => active && setHints(h))
    return () => {
      active = false
    }
  }, [])

  if (hints.length === 0) return null
  return (
    <section aria-label="Hinweise zu den Schnittstellen">
      <StatusHints hints={hints} withLink />
    </section>
  )
}
