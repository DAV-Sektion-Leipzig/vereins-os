import { useState } from 'react'
import { CircleAlertIcon, PlusIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Section } from '@/features/ad/personen/Section'
import {
  assignTemplate,
  revokeTemplate,
  setAssignmentReferate,
  type Assignment,
  type AssignmentsData,
} from '@/features/ad/personen/data'
import type { NamedOption } from '@/features/shared/Eigenschaftsformular'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate } from '@/lib/format'

// T084 (US-AD-11, US-AD-21): wirksame Vorlagen mit Referaten; hinzufügen (nur nicht zugewiesene, bei Reichweite
// Referat Mehrfachauswahl, R31), Referate ändern, entziehen mit Bestätigung. Rechte prüft die Datenbank (AD ≥ bearbeiten).
type Props = { personId: string; data: AssignmentsData; canEdit: boolean }

export function RechtevorlagenAbschnitt({ personId, data, canEdit }: Props) {
  const revalidator = useRevalidator()
  const [adding, setAdding] = useState(false)
  const [editingReferate, setEditingReferate] = useState<Assignment | null>(null)
  const [revoking, setRevoking] = useState<Assignment | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  const assignedIds = new Set(data.assignments.map((a) => a.template_id))
  const available = data.templates.filter((t) => !assignedIds.has(t.id))

  async function run(action: () => Promise<unknown>) {
    setPending(true)
    setError(null)
    try {
      const err = await action()
      if (err) {
        setError(toMessage(err).text)
        return false
      }
      revalidator.revalidate()
      return true
    } catch (caught) {
      setError(toMessage(caught).text)
      return false
    } finally {
      setPending(false)
    }
  }

  return (
    <Section id="rechtevorlagen" title="Rechtevorlagen">
      {data.assignments.length === 0 && <p className="text-sm text-muted-foreground">Noch keine Rechtevorlage zugewiesen.</p>}

      {data.assignments.length > 0 && (
        <ul className="flex flex-col divide-y rounded-xl border">
          {data.assignments.map((a) =>
            editingReferate?.id === a.id ? (
              <li key={a.id} className="p-3">
                <ReferateForm
                  title={`Referate für „${a.templateName}“`}
                  referate={data.referate}
                  initial={a.referate.map((r) => r.id)}
                  pending={pending}
                  error={error}
                  onSubmit={async (ids) => {
                    if (await run(() => setAssignmentReferate(a.id, ids))) setEditingReferate(null)
                  }}
                  onCancel={() => {
                    setEditingReferate(null)
                    setError(null)
                  }}
                />
              </li>
            ) : (
              <li key={a.id} className="flex flex-col gap-2 px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex flex-col gap-0.5 text-sm">
                  <span className="font-medium">{a.templateName}</span>
                  {a.needsReferate && (
                    <span className="text-muted-foreground">
                      Reichweite Referat: {a.referate.length > 0 ? a.referate.map((r) => r.name).join(', ') : '–'}
                    </span>
                  )}
                  <span className="text-muted-foreground">zugewiesen am {formatDate(a.assigned_at)}</span>
                </div>
                {canEdit && (
                  <div className="flex flex-wrap gap-2">
                    {a.needsReferate && (
                      <Button variant="outline" size="sm" onClick={() => setEditingReferate(a)} disabled={pending}>
                        Referate ändern
                      </Button>
                    )}
                    <Button variant="outline" size="sm" onClick={() => setRevoking(a)} disabled={pending}>
                      Entziehen
                    </Button>
                  </div>
                )}
              </li>
            ),
          )}
        </ul>
      )}

      {error && !editingReferate && !adding && (
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}

      {canEdit && !adding && (
        <Button variant="outline" className="self-start" onClick={() => setAdding(true)} disabled={available.length === 0 || pending}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Vorlage hinzufügen
        </Button>
      )}
      {canEdit && !adding && available.length === 0 && (
        <p className="text-sm text-muted-foreground">Alle Vorlagen sind zugewiesen.</p>
      )}

      {adding && (
        <AssignForm
          templates={available}
          referate={data.referate}
          pending={pending}
          error={error}
          onSubmit={async (templateId, ids) => {
            if (await run(() => assignTemplate(personId, templateId, ids))) setAdding(false)
          }}
          onCancel={() => {
            setAdding(false)
            setError(null)
          }}
        />
      )}

      <Dialog open={revoking !== null} onOpenChange={(open) => !open && !pending && setRevoking(null)}>
        <DialogContent showCloseButton={false}>
          <DialogHeader>
            <DialogTitle>Vorlage entziehen?</DialogTitle>
            <DialogDescription>
              „{revoking?.templateName}“ wird entzogen. Die Rechte enden sofort; eine laufende Anmeldung spätestens nach einer Stunde.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRevoking(null)} disabled={pending}>
              Abbrechen
            </Button>
            <Button
              variant="destructive"
              disabled={pending}
              onClick={async () => {
                if (revoking && (await run(() => revokeTemplate(personId, revoking.template_id)))) setRevoking(null)
              }}
            >
              {pending ? 'Wird entzogen …' : 'Entziehen'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Section>
  )
}

function ReferateCheckboxes({ referate, selected, onChange }: { referate: NamedOption[]; selected: string[]; onChange: (ids: string[]) => void }) {
  // Inaktive Referate nicht neu anbieten (US-AD-21 AK5); bereits gewählte bleiben sichtbar
  const options = referate.filter((r) => r.is_active || selected.includes(r.id))
  return (
    <fieldset className="flex flex-col gap-2">
      <legend className="mb-1 text-sm font-medium">Referate</legend>
      <div className="flex flex-wrap gap-x-6 gap-y-2">
        {options.map((r) => (
          <label key={r.id} className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={selected.includes(r.id)}
              onChange={(e) => onChange(e.target.checked ? [...selected, r.id] : selected.filter((x) => x !== r.id))}
              className="size-4 accent-primary"
            />
            {r.name}
            {!r.is_active && <span className="text-muted-foreground">(inaktiv)</span>}
          </label>
        ))}
      </div>
    </fieldset>
  )
}

function ErrorLine({ text }: { text: string | null }) {
  if (!text) return null
  return (
    <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}

function ReferateForm({
  title,
  referate,
  initial,
  pending,
  error,
  onSubmit,
  onCancel,
}: {
  title: string
  referate: NamedOption[]
  initial: string[]
  pending: boolean
  error: string | null
  onSubmit: (ids: string[]) => void
  onCancel: () => void
}) {
  const [selected, setSelected] = useState(initial)
  const [localError, setLocalError] = useState<string | null>(null)
  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault()
        if (selected.length === 0) return setLocalError(MESSAGES.referatRequired)
        setLocalError(null)
        onSubmit(selected)
      }}
    >
      <p className="font-medium">{title}</p>
      <ReferateCheckboxes referate={referate} selected={selected} onChange={setSelected} />
      <ErrorLine text={localError ?? error} />
      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Speichern …' : 'Speichern'}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}

function AssignForm({
  templates,
  referate,
  pending,
  error,
  onSubmit,
  onCancel,
}: {
  templates: AssignmentsData['templates']
  referate: NamedOption[]
  pending: boolean
  error: string | null
  onSubmit: (templateId: string, referate: string[]) => void
  onCancel: () => void
}) {
  const [templateId, setTemplateId] = useState('')
  const [selected, setSelected] = useState<string[]>([])
  const [localError, setLocalError] = useState<string | null>(null)
  const template = templates.find((t) => t.id === templateId)

  return (
    <form
      className="flex max-w-xl flex-col gap-4 rounded-xl border p-4"
      onSubmit={(e) => {
        e.preventDefault()
        if (!template) return setLocalError('Bitte eine Vorlage wählen.')
        if (template.needsReferate && selected.length === 0) return setLocalError(MESSAGES.referatRequired)
        setLocalError(null)
        onSubmit(template.id, template.needsReferate ? selected : [])
      }}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="assign-template">Vorlage</Label>
        <select
          id="assign-template"
          value={templateId}
          onChange={(e) => setTemplateId(e.target.value)}
          className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
        >
          <option value="">– bitte wählen –</option>
          {templates.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
              {t.needsReferate && ' (Reichweite Referat)'}
            </option>
          ))}
        </select>
        {template?.description && <p className="text-sm text-muted-foreground">{template.description}</p>}
      </div>
      {template?.needsReferate && <ReferateCheckboxes referate={referate} selected={selected} onChange={setSelected} />}
      <ErrorLine text={localError ?? error} />
      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Zuweisen …' : 'Zuweisen'}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}
