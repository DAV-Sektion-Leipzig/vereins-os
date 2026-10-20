// Platzhalter für Routen, die mit späteren Stories umgesetzt werden (tasks.md T026).
export function PlaceholderPage({ title }: { title: string }) {
  return (
    <section className="flex flex-col gap-2">
      <h1 className="text-xl font-semibold">{title}</h1>
      <p className="text-sm text-muted-foreground">Dieser Bereich folgt.</p>
    </section>
  )
}
