import { useState, type FormEvent } from 'react'
import { KeyRoundIcon, MailIcon, PencilIcon, PlusIcon, PowerIcon, PowerOffIcon, ShieldCheckIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useScAccess } from '@/features/sc/access'
import {
  KIND_LABELS,
  saveConnection,
  sendTestMail,
  setKey,
  setModules,
  setState,
  type Connection,
  type ConnectionsData,
  type ModuleOption,
} from '@/features/sc/data'
import { ErrorText, LoadFailed, StateBadge, StatusHints } from '@/features/sc/ui'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate, formatDateTime } from '@/lib/format'

type DialogState =
  | { kind: 'connection'; connection: Connection | null }
  | { kind: 'key'; connection: Connection }
  | { kind: 'modules'; connection: Connection }
  | { kind: 'disable'; connection: Connection }
  | null

// US-SC-01 bis US-SC-06: Anbindungen mit Zustand, Key (nur letzte 4 Zeichen), Grenzen und freigegebenen Modulen.
export function AnbindungenPage() {
  const data = useLoaderData() as ConnectionsData
  const { canEdit, canManage } = useScAccess()
  const revalidator = useRevalidator()
  const [dialog, setDialog] = useState<DialogState>(null)
  const [pending, setPending] = useState<string | null>(null)

  if (data.failed) return <LoadFailed title="Anbindungen" />

  function done(text: string) {
    toast.success(text)
    setDialog(null)
    revalidator.revalidate()
  }

  async function test(c: Connection) {
    setPending(`test-${c.id}`)
    const result = await sendTestMail(c.id)
    setPending(null)
    if (!result.ok) toast.error(toMessage(result.code).text)
    else if (result.data.ok) toast.success('Test erfolgreich: Die Test-E-Mail ist an deine Login-Adresse unterwegs.')
    else toast.error(`Test fehlgeschlagen: ${result.data.message ?? 'unbekannter Fehler'}`)
    revalidator.revalidate()
  }

  async function activate(c: Connection) {
    setPending(`state-${c.id}`)
    const { error } = await setState(c.id, 'active')
    setPending(null)
    if (error) toast.error(toMessage(error).text)
    else done('Die Anbindung ist aktiv.')
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold">Anbindungen</h1>
          <p className="text-sm text-muted-foreground">
            Externe Dienste, über die das Vereins OS E-Mails verschickt. Den API-Key siehst du nach dem Speichern nicht mehr.
          </p>
        </div>
        {canManage && (
          <Button onClick={() => setDialog({ kind: 'connection', connection: null })}>
            <PlusIcon data-icon="inline-start" aria-hidden="true" />
            Anbindung anlegen
          </Button>
        )}
      </div>

      <StatusHints hints={data.hints} />

      {data.connections.length === 0 ? (
        <p className="text-sm text-muted-foreground">Es ist noch keine Schnittstelle angebunden.</p>
      ) : (
        <ul className="grid gap-4 lg:grid-cols-2">
          {data.connections.map((c) => (
            <li key={c.id} className="flex flex-col gap-3 rounded-xl border bg-card p-4">
              <div className="flex flex-wrap items-start justify-between gap-2">
                <div className="flex min-w-0 flex-col">
                  <h2 className="truncate font-medium">{c.name}</h2>
                  <span className="text-sm text-muted-foreground">{KIND_LABELS[c.kind] ?? c.kind}</span>
                </div>
                <StateBadge state={c.state} />
              </div>

              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-sm">
                <dt className="text-muted-foreground">Absender</dt>
                <dd className="min-w-0 break-words">
                  {c.sender_name} &lt;{c.sender_email}&gt;
                </dd>
                <dt className="text-muted-foreground">API-Key</dt>
                <dd>{c.key_last4 ? `hinterlegt: …${c.key_last4}` : <span className="text-destructive">fehlt</span>}</dd>
                <dt className="text-muted-foreground">läuft ab</dt>
                <dd className="tabular-nums">{c.key_expires_on ? formatDate(c.key_expires_on) : 'kein Ablaufdatum'}</dd>
                <dt className="text-muted-foreground">gewechselt</dt>
                <dd className="tabular-nums">{c.key_changed_at ? formatDateTime(c.key_changed_at) : '–'}</dd>
                <dt className="text-muted-foreground">letzter Erfolg</dt>
                <dd className="tabular-nums">{c.last_success_at ? formatDateTime(c.last_success_at) : '–'}</dd>
                {c.last_error && (
                  <>
                    <dt className="text-muted-foreground">letzter Fehler</dt>
                    <dd className="min-w-0 break-words text-destructive">
                      {c.last_error_at && <span className="tabular-nums">{formatDateTime(c.last_error_at)}: </span>}
                      {c.last_error}
                    </dd>
                  </>
                )}
                <dt className="text-muted-foreground">heute versendet</dt>
                <dd className="tabular-nums">
                  {c.sentToday} von {c.daily_limit} (höchstens {c.hourly_limit} je Stunde)
                </dd>
                <dt className="text-muted-foreground">Module</dt>
                <dd>
                  {c.modules.length
                    ? c.modules.map((code) => data.modules.find((m) => m.code === code)?.name ?? code).join(', ')
                    : 'keine'}
                </dd>
              </dl>

              {(canEdit || canManage) && (
                <div className="flex flex-wrap gap-2 border-t pt-3">
                  {canEdit && (
                    <Button variant="outline" size="sm" onClick={() => test(c)} disabled={pending !== null || !c.key_last4}>
                      <MailIcon data-icon="inline-start" aria-hidden="true" />
                      {pending === `test-${c.id}` ? 'Wird gesendet …' : 'Test-E-Mail senden'}
                    </Button>
                  )}
                  {canManage && (
                    <>
                      {c.state === 'active' ? (
                        <Button variant="outline" size="sm" onClick={() => setDialog({ kind: 'disable', connection: c })}>
                          <PowerOffIcon data-icon="inline-start" aria-hidden="true" />
                          abschalten
                        </Button>
                      ) : (
                        <Button variant="outline" size="sm" onClick={() => activate(c)} disabled={pending !== null}>
                          <PowerIcon data-icon="inline-start" aria-hidden="true" />
                          aktivieren
                        </Button>
                      )}
                      <Button variant="ghost" size="sm" onClick={() => setDialog({ kind: 'key', connection: c })}>
                        <KeyRoundIcon data-icon="inline-start" aria-hidden="true" />
                        {c.key_last4 ? 'Key wechseln' : 'Key hinterlegen'}
                      </Button>
                      <Button variant="ghost" size="sm" onClick={() => setDialog({ kind: 'modules', connection: c })}>
                        <ShieldCheckIcon data-icon="inline-start" aria-hidden="true" />
                        Module freigeben
                      </Button>
                      <Button variant="ghost" size="sm" onClick={() => setDialog({ kind: 'connection', connection: c })}>
                        <PencilIcon data-icon="inline-start" aria-hidden="true" />
                        bearbeiten
                      </Button>
                    </>
                  )}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {dialog?.kind === 'connection' && (
        <ConnectionDialog connection={dialog.connection} onClose={() => setDialog(null)} onSaved={done} />
      )}
      {dialog?.kind === 'key' && <KeyDialog connection={dialog.connection} onClose={() => setDialog(null)} onSaved={done} />}
      {dialog?.kind === 'modules' && (
        <ModulesDialog connection={dialog.connection} modules={data.modules} onClose={() => setDialog(null)} onSaved={done} />
      )}
      {dialog?.kind === 'disable' && (
        <DisableDialog connection={dialog.connection} onClose={() => setDialog(null)} onSaved={done} />
      )}
    </section>
  )
}

function ConnectionDialog({
  connection,
  onClose,
  onSaved,
}: {
  connection: Connection | null
  onClose: () => void
  onSaved: (text: string) => void
}) {
  const [name, setName] = useState(connection?.name ?? 'E-Mail Sektion')
  const [senderEmail, setSenderEmail] = useState(connection?.sender_email ?? 'noreply@vereinsos.dav-leipzig.de')
  const [senderName, setSenderName] = useState(connection?.sender_name ?? 'Vereins OS')
  const [expires, setExpires] = useState(connection?.key_expires_on ?? '')
  const [hourly, setHourly] = useState(String(connection?.hourly_limit ?? 100))
  const [daily, setDaily] = useState(String(connection?.daily_limit ?? 300))
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    const hourlyLimit = Number.parseInt(hourly, 10)
    const dailyLimit = Number.parseInt(daily, 10)
    if (!(hourlyLimit >= 1 && hourlyLimit <= 100 && dailyLimit >= 1 && dailyLimit <= 300)) {
      setError(MESSAGES.scLimitInvalid)
      return
    }
    setPending(true)
    const { error: saveError } = await saveConnection({
      id: connection?.id ?? null,
      name,
      sender_email: senderEmail,
      sender_name: senderName,
      key_expires_on: expires || null,
      hourly_limit: hourlyLimit,
      daily_limit: dailyLimit,
    })
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved(connection ? 'Die Anbindung ist gespeichert.' : 'Die Anbindung ist angelegt. Hinterlege jetzt den API-Key.')
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>{connection ? 'Anbindung bearbeiten' : 'Anbindung anlegen'}</DialogTitle>
            <DialogDescription>
              Art: E-Mail (Brevo). Die Absenderadresse muss in Brevo eingerichtet sein. Nach einer Änderung am Absender ist
              vor dem Aktivieren eine erfolgreiche Test-E-Mail nötig.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <Label htmlFor="sc-name">Name</Label>
            <Input id="sc-name" maxLength={80} value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="sc-sender">Absenderadresse</Label>
              <Input id="sc-sender" type="email" autoComplete="off" value={senderEmail} onChange={(e) => setSenderEmail(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="sc-sender-name">Absendername</Label>
              <Input id="sc-sender-name" maxLength={80} value={senderName} onChange={(e) => setSenderName(e.target.value)} />
            </div>
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            <div className="flex flex-col gap-2">
              <Label htmlFor="sc-expires">Key läuft ab (optional)</Label>
              <Input id="sc-expires" type="date" value={expires} onChange={(e) => setExpires(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="sc-hourly">je Stunde (höchstens 100)</Label>
              <Input id="sc-hourly" type="number" min={1} max={100} value={hourly} onChange={(e) => setHourly(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="sc-daily">je Tag (höchstens 300)</Label>
              <Input id="sc-daily" type="number" min={1} max={300} value={daily} onChange={(e) => setDaily(e.target.value)} />
            </div>
          </div>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function KeyDialog({ connection, onClose, onSaved }: { connection: Connection; onClose: () => void; onSaved: (text: string) => void }) {
  const [key, setKeyValue] = useState('')
  const [expires, setExpires] = useState(connection.key_expires_on ?? '')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!key.trim()) {
      setError(MESSAGES.scKeyInvalid)
      return
    }
    setPending(true)
    const { error: saveError } = await setKey(connection.id, key.trim(), expires || null)
    setPending(false)
    setKeyValue('')
    if (saveError) setError(toMessage(saveError).text)
    else onSaved('Der Key ist hinterlegt. Sende jetzt eine Test-E-Mail.')
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>{connection.key_last4 ? 'API-Key wechseln' : 'API-Key hinterlegen'}</DialogTitle>
            <DialogDescription>
              {connection.key_last4 ? `Hinterlegt: …${connection.key_last4}. ` : ''}
              Den Key erzeugst du im Brevo-Konto der Sektion. Nach dem Speichern ist er nicht mehr lesbar. Eine aktive Anbindung
              ist bis zur erfolgreichen Test-E-Mail gestört.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <Label htmlFor="sc-key">Neuer API-Key</Label>
            <Input id="sc-key" type="password" autoComplete="new-password" spellCheck={false} value={key} onChange={(e) => setKeyValue(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="sc-key-expires">läuft ab (optional)</Label>
            <Input id="sc-key-expires" type="date" value={expires} onChange={(e) => setExpires(e.target.value)} className="sm:w-48" />
          </div>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function ModulesDialog({
  connection,
  modules,
  onClose,
  onSaved,
}: {
  connection: Connection
  modules: ModuleOption[]
  onClose: () => void
  onSaved: (text: string) => void
}) {
  const [selected, setSelected] = useState<string[]>(connection.modules)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  function toggle(code: string, on: boolean) {
    setSelected((s) => (on ? [...s, code] : s.filter((c) => c !== code)))
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPending(true)
    const { error: saveError } = await setModules(connection.id, selected)
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved('Die Freigaben sind gespeichert.')
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Module freigeben</DialogTitle>
            <DialogDescription>
              Nur freigegebene Module dürfen über „{connection.name}“ E-Mails verschicken. Schon wartende E-Mails gehen noch hinaus.
            </DialogDescription>
          </DialogHeader>
          <fieldset className="grid gap-2 sm:grid-cols-2">
            <legend className="sr-only">Module</legend>
            {modules.map((m) => (
              <label key={m.code} className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={selected.includes(m.code)}
                  onChange={(e) => toggle(m.code, e.target.checked)}
                  className="size-4 cursor-pointer accent-primary"
                />
                {m.name}
              </label>
            ))}
          </fieldset>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function DisableDialog({ connection, onClose, onSaved }: { connection: Connection; onClose: () => void; onSaved: (text: string) => void }) {
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function confirm() {
    setPending(true)
    const { error: saveError } = await setState(connection.id, 'disabled')
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved('Die Anbindung ist abgeschaltet.')
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Anbindung abschalten?</DialogTitle>
          <DialogDescription>
            Über „{connection.name}“ gehen dann keine E-Mails mehr hinaus. Wartende E-Mails bleiben im Postausgang und gehen nach
            dem Aktivieren hinaus; nach 7 Tagen gelten sie als „zu alt“.
          </DialogDescription>
        </DialogHeader>
        <ErrorText text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="button" variant="destructive" onClick={confirm} disabled={pending}>
            {pending ? 'Wird abgeschaltet …' : 'Abschalten'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
