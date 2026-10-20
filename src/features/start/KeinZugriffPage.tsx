import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { MESSAGES } from '@/lib/errors'

// US-AD-05 AK3: ohne Rechte keine Daten, nur dieser Hinweis.
export function KeinZugriffPage() {
  return (
    <section className="flex flex-col items-start gap-4">
      <h1 className="text-xl font-semibold">Kein Zugriff</h1>
      <p>{MESSAGES.forbidden}</p>
      <Button asChild>
        <Link to="/">Zur Startseite</Link>
      </Button>
    </section>
  )
}
