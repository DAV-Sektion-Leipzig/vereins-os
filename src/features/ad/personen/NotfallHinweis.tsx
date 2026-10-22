import { useState } from 'react'
import { ShieldAlertIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { acknowledgeEmergency, type EmergencyNotice } from '@/features/ad/personen/data'
import { toMessage } from '@/lib/errors'
import { formatDate, formatTime } from '@/lib/format'

// T072 (US-AD-15 AK2): Hinweis auf Anmeldungen des Notfall-Admins seit dem letzten „Zur Kenntnis genommen“.
export function NotfallHinweis({ notice }: { notice: EmergencyNotice }) {
  const revalidator = useRevalidator()
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function acknowledge() {
    setPending(true)
    setError(null)
    const err = await acknowledgeEmergency()
    setPending(false)
    if (err) {
      setError(toMessage(err).text)
      return
    }
    revalidator.revalidate()
  }

  const count = notice.count === 1 ? 'einmal' : `${notice.count}-mal`
  const when = notice.last_at ? `, zuletzt am ${formatDate(notice.last_at)} um ${formatTime(notice.last_at)}` : ''

  return (
    <div
      role="status"
      className="flex flex-col gap-3 rounded-xl border border-status-locked/40 bg-status-locked-bg p-4 sm:flex-row sm:items-center sm:justify-between"
    >
      <p className="flex items-start gap-2 text-sm">
        <ShieldAlertIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-status-locked" />
        <span>
          Der Notfall-Admin hat sich {count} angemeldet{when}.
          {error && <span className="block text-destructive">{error}</span>}
        </span>
      </p>
      <Button variant="outline" onClick={acknowledge} disabled={pending} className="shrink-0 self-start sm:self-auto">
        {pending ? 'Wird gespeichert …' : 'Zur Kenntnis genommen'}
      </Button>
    </div>
  )
}
