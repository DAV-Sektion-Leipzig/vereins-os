import type { ReactNode } from 'react'

// Abschnitt des Personendetails (spec.md AD Abschnitt 6): Überschrift mit Anker für die Abschnitte.
export function Section({ id, title, children }: { id: string; title: string; children: ReactNode }) {
  return (
    <section aria-labelledby={`${id}-heading`} className="flex flex-col gap-3">
      <h2 id={`${id}-heading`} className="font-medium">
        {title}
      </h2>
      {children}
    </section>
  )
}
