import { useState, type FormEvent } from 'react'
import { CircleAlertIcon, InfoIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { AccessStatusBadge } from '@/components/AccessStatusBadge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Section } from '@/features/ad/personen/Section'
import { saveLoginEmail, type AccessInfo, type PersonRow } from '@/features/ad/personen/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDateTime } from '@/lib/format'
import { callFunction } from '@/lib/functions'

// T095 (US-AD-08, US-AD-09): Login-Adresse nach R20, Einladen / Erneut einladen (R17), Sperren mit Bestätigung, Entsperren.
type Props = { person: PersonRow; access: AccessInfo | null; lockedByName: string | null; hasTemplate: boolean; canEdit: boolean }

export function ZugangAbschnitt({ person, access, lockedByName, hasTemplate, canEdit }: Props) {
  const revalidator = useRevalidator()
  const status = person.access_status
  const [editingEmail, setEditingEmail] = useState(false)
  const [locking, setLocking] = useState(false)
  const [pending, setPending] = useState<string | null>(null)
  const [message, setMessage] = useState<{ kind: 'error' | 'info'; text: string } | null>(null)

  const emailEditable = status === 'none' || status === 'invited'
  const canInvite = status === 'none' || status === 'invited'

  async function run(action: string, fn: () => Promise<{ ok: boolean; code?: string }>) {
    setPending(action)
    setMessage(null)
    try {
      const result = await fn()
      if (!result.ok) {
        setMessage(toMessage(result.code ?? 'AD_UNEXPECTED'))
        return false
      }
      revalidator.revalidate()
      return true
    } finally {
      setPending(null)
    }
  }

  async function invite() {
    await run('invite', () => callFunction('ad-invite', { person_id: person.person_id }))
  }

  async function lock() {
    if (await run('lock', () => callFunction('ad-access', { person_id: person.person_id, action: 'lock' }))) setLocking(false)
  }

  async function unlock() {
    await run('unlock', () => callFunction('ad-access', { person_id: person.person_id, action: 'unlock' }))
  }

  return (
    <Section id="zugang" title="Zugang">
      {editingEmail ? (
        <EmailForm
          person={person}
          access={access}
          onDone={(info) => {
            setEditingEmail(false)
            if (info) setMessage(info)
            revalidator.revalidate()
          }}
          onCancel={() => setEditingEmail(false)}
        />
      ) : (
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
          <dt className="text-muted-foreground">Login-Adresse</dt>
          <dd className="break-all">{access?.login_email ?? <span className="text-muted-foreground">–</span>}</dd>
          <dt className="text-muted-foreground">Status</dt>
          <dd>
            <AccessStatusBadge status={status} />
          </dd>
          {access?.last_invited_at && (
            <>
              <dt className="text-muted-foreground">Zuletzt eingeladen</dt>
              <dd>{formatDateTime(access.last_invited_at)}</dd>
            </>
          )}
          {status === 'locked' && access?.locked_at && (
            <>
              <dt className="text-muted-foreground">Gesperrt</dt>
              <dd>
                am {formatDateTime(access.locked_at)}
                {lockedByName && ` von ${lockedByName}`}
              </dd>
            </>
          )}
        </dl>
      )}

      {message && (
        <p role={message.kind === 'error' ? 'alert' : 'status'} className={`flex items-center gap-2 text-sm ${message.kind === 'error' ? 'text-destructive' : ''}`}>
          {message.kind === 'error' ? (
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          ) : (
            <InfoIcon aria-hidden="true" className="size-4 shrink-0 text-primary" />
          )}
          {message.text}
        </p>
      )}

      {canEdit && !editingEmail && (
        <div className="flex flex-col gap-2">
          <div className="flex flex-wrap gap-2">
            {emailEditable ? (
              <Button variant="outline" onClick={() => setEditingEmail(true)} disabled={pending !== null}>
                {access ? 'Login-Adresse ändern' : 'Login-Adresse festlegen'}
              </Button>
            ) : (
              <Button variant="outline" disabled title={MESSAGES.emailLocked}>
                Login-Adresse ändern
              </Button>
            )}
            {canInvite && (
              <Button onClick={invite} disabled={pending !== null || !access?.login_email || !hasTemplate}>
                {pending === 'invite' ? 'Wird verschickt …' : status === 'invited' ? 'Erneut einladen' : 'Einladen'}
              </Button>
            )}
            {(status === 'invited' || status === 'active') && (
              <Button variant="destructive" onClick={() => setLocking(true)} disabled={pending !== null}>
                Sperren
              </Button>
            )}
            {status === 'locked' && (
              <Button onClick={unlock} disabled={pending !== null}>
                {pending === 'unlock' ? 'Wird entsperrt …' : 'Entsperren'}
              </Button>
            )}
          </div>
          {!emailEditable && <p className="text-sm text-muted-foreground">{MESSAGES.emailLocked}</p>}
          {canInvite && access?.login_email && !hasTemplate && <p className="text-sm text-muted-foreground">{MESSAGES.noTemplate}</p>}
          {canInvite && !access?.login_email && <p className="text-sm text-muted-foreground">Zum Einladen zuerst eine Login-Adresse festlegen.</p>}
        </div>
      )}

      <Dialog open={locking} onOpenChange={(open) => !open && pending === null && setLocking(false)}>
        <DialogContent showCloseButton={false}>
          <DialogHeader>
            <DialogTitle>Zugang sperren?</DialogTitle>
            <DialogDescription>
              Eine neue Anmeldung ist danach nicht mehr möglich. Bereits angemeldete Nutzer verlieren den Zugriff spätestens nach einer Stunde.
              Eigenschaften und Rechtevorlagen bleiben erhalten.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setLocking(false)} disabled={pending !== null}>
              Abbrechen
            </Button>
            <Button variant="destructive" onClick={lock} disabled={pending !== null}>
              {pending === 'lock' ? 'Wird gesperrt …' : 'Sperren'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Section>
  )
}

function EmailForm({
  person,
  access,
  onDone,
  onCancel,
}: {
  person: PersonRow
  access: AccessInfo | null
  onDone: (info: { kind: 'info'; text: string } | null) => void
  onCancel: () => void
}) {
  const [email, setEmail] = useState(access?.login_email ?? '')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    setPending(true)
    try {
      if (person.access_status === 'invited') {
        // R20: bei „eingeladen“ über ad-access, damit der alte Link ungültig wird (US-AD-08 AK7)
        const result = await callFunction<{ code?: string }>('ad-access', { person_id: person.person_id, action: 'change_email', login_email: email.trim() })
        if (!result.ok) return setError(toMessage(result.code).text)
        onDone(result.data.code ? (toMessage(result.data.code) as { kind: 'info'; text: string }) : null)
        return
      }
      const err = await saveLoginEmail(person.person_id, email, access !== null)
      if (err) return setError(toMessage(err).text)
      onDone(null)
    } finally {
      setPending(false)
    }
  }

  return (
    <form className="flex max-w-md flex-col gap-4" onSubmit={onSubmit} noValidate>
      <div className="flex flex-col gap-2">
        <Label htmlFor="access-email">
          Login-Adresse <span className="font-normal text-muted-foreground">(@dav-leipzig.de)</span>
        </Label>
        <Input id="access-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required aria-invalid={!!error || undefined} autoComplete="off" />
      </div>
      {person.access_status === 'invited' && (
        <p className="text-sm text-muted-foreground">Die Einladung wird zurückgenommen; der alte Link ist danach ungültig.</p>
      )}
      {error && (
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}
      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending || !email.trim()}>
          {pending ? 'Speichern …' : 'Speichern'}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}
