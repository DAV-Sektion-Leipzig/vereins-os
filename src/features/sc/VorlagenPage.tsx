import { useRef, useState, type FormEvent } from 'react'
import { EyeIcon, PencilIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useScAccess } from '@/features/sc/access'
import { previewOccasion, saveOccasion, type Occasion, type OccasionsData } from '@/features/sc/data'
import { ErrorText, LoadFailed } from '@/features/sc/ui'
import { toMessage } from '@/lib/errors'
import { formatDateTime } from '@/lib/format'

const SUBJECT_MAX = 150
const BODY_MAX = 2000

// US-SC-07: Anlässe mit Vorlage; Betreff und Text sieht und pflegt nur, wer SC bearbeiten darf (Erhebung E1).
export function VorlagenPage() {
  const data = useLoaderData() as OccasionsData
  const { canEdit } = useScAccess()
  const revalidator = useRevalidator()
  const [editing, setEditing] = useState<Occasion | null>(null)

  if (data.failed) return <LoadFailed title="Vorlagen" />

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">Vorlagen</h1>
        <p className="text-sm text-muted-foreground">
          Jeder Anlass hat eine eigene E-Mail. Sprich mit „du“ an und nenne keine Namen oder andere Personendaten; die E-Mail
          enthält nur einen kurzen Hinweis und einen Link ins Vereins OS.
        </p>
      </div>

      <ul className="flex flex-col gap-4">
        {data.occasions.map((o) => (
          <li key={o.code} className="flex flex-col gap-3 rounded-xl border bg-card p-4">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div className="flex min-w-0 flex-col">
                <h2 className="font-medium">{o.name}</h2>
                <span className="text-sm text-muted-foreground">
                  Modul {o.module_code} · {o.description}
                </span>
              </div>
              {canEdit && (
                <Button variant="ghost" size="sm" onClick={() => setEditing(o)}>
                  <PencilIcon data-icon="inline-start" aria-hidden="true" />
                  bearbeiten
                </Button>
              )}
            </div>
            {canEdit && o.subject !== null && (
              <div className="flex flex-col gap-1 rounded-lg bg-muted px-3 py-2 text-sm">
                <span className="font-medium">{o.subject}</span>
                <span className="whitespace-pre-line text-muted-foreground">{o.body}</span>
              </div>
            )}
            <p className="text-xs text-muted-foreground">
              Platzhalter: {o.placeholders.map((p) => `{${p}}`).join(', ') || 'keine'} · geändert {formatDateTime(o.updated_at)}
            </p>
          </li>
        ))}
      </ul>

      {editing && (
        <OccasionDialog
          occasion={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            toast.success('Die Vorlage ist gespeichert.')
            setEditing(null)
            revalidator.revalidate()
          }}
        />
      )}
    </section>
  )
}

function OccasionDialog({ occasion, onClose, onSaved }: { occasion: Occasion; onClose: () => void; onSaved: () => void }) {
  const [subject, setSubject] = useState(occasion.subject ?? '')
  const [body, setBody] = useState(occasion.body ?? '')
  const [preview, setPreview] = useState<{ subject: string; body: string } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)
  const bodyRef = useRef<HTMLTextAreaElement>(null)

  function insert(placeholder: string) {
    const token = `{${placeholder}}`
    const el = bodyRef.current
    if (!el) return setBody((b) => b + token)
    const start = el.selectionStart ?? body.length
    const end = el.selectionEnd ?? body.length
    setBody(body.slice(0, start) + token + body.slice(end))
    requestAnimationFrame(() => {
      el.focus()
      el.setSelectionRange(start + token.length, start + token.length)
    })
  }

  async function showPreview() {
    setError(null)
    const { data, error: previewError } = await previewOccasion(occasion.code, subject, body)
    if (previewError) {
      setError(toMessage(previewError).text)
      setPreview(null)
    } else {
      const row = (data as { subject: string; body: string }[])[0]
      setPreview(row ?? null)
    }
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    setPending(true)
    const { error: saveError } = await saveOccasion(occasion.code, subject, body)
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-2xl">
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Vorlage: {occasion.name}</DialogTitle>
            <DialogDescription>Der neue Text gilt für E-Mails, die nach dem Speichern verschickt werden.</DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <div className="flex items-baseline justify-between gap-2">
              <Label htmlFor="sc-subject">Betreff</Label>
              <span className="text-xs text-muted-foreground tabular-nums">
                {subject.length}/{SUBJECT_MAX}
              </span>
            </div>
            <Input id="sc-subject" maxLength={SUBJECT_MAX} value={subject} onChange={(e) => setSubject(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <div className="flex items-baseline justify-between gap-2">
              <Label htmlFor="sc-body">Text</Label>
              <span className="text-xs text-muted-foreground tabular-nums">
                {body.length}/{BODY_MAX}
              </span>
            </div>
            <textarea
              id="sc-body"
              ref={bodyRef}
              rows={8}
              maxLength={BODY_MAX}
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className="min-h-32 rounded-lg border bg-background px-2.5 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
            />
            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-xs text-muted-foreground">Einfügen:</span>
              {occasion.placeholders.map((p) => (
                <Button key={p} type="button" variant="outline" size="xs" onClick={() => insert(p)}>
                  {`{${p}}`}
                </Button>
              ))}
            </div>
          </div>
          {preview && (
            <div className="flex flex-col gap-1 rounded-lg bg-muted px-3 py-2 text-sm" aria-live="polite">
              <span className="text-xs text-muted-foreground">Vorschau mit Beispielwerten</span>
              <span className="font-medium">{preview.subject}</span>
              <span className="whitespace-pre-line">{preview.body}</span>
            </div>
          )}
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={showPreview} disabled={pending}>
              <EyeIcon data-icon="inline-start" aria-hidden="true" />
              Vorschau
            </Button>
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
